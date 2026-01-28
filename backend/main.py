import json
import random
import os
import shutil
import uuid
from datetime import datetime
from typing import Optional

import jwt
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Query, UploadFile, File, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import select, or_, and_, func
from sqlalchemy.ext.asyncio import AsyncSession

from database import engine, Base, async_session_factory
from models import Message, User, DirectChat, GroupChat, GroupMember, GameSession, GamePlayer, GameStats
from schemas import (
    UserCreate, UserResponse, UserLogin, Token,
    UpdateAvatar, UpdateProfile, DirectChatResponse
)
from security import get_password_hash, verify_password, create_access_token, SECRET_KEY, ALGORITHM


#ИНИЦИАЛИЗАЦИЯ

os.makedirs("uploads", exist_ok=True)


async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(
    title="Omega Chat API",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

GAME_TYPES = ["dice", "wheel", "rps", "random", "who_am_i", "alias", "codenames"]

#ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ

async def get_current_user(token: str = Query(...)) -> dict:
    """Получить текущего пользователя из токена"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        username = payload.get("username")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return {"id": int(user_id), "username": username}
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")


def format_time(dt: datetime) -> str:
    """Форматирование времени для отображения"""
    now = datetime.utcnow()
    diff = now - dt
    
    if diff.days == 0:
        return dt.strftime("%H:%M")
    elif diff.days == 1:
        return "вчера"
    elif diff.days < 7:
        days = ["пн", "вт", "ср", "чт", "пт", "сб", "вс"]
        return days[dt.weekday()]
    else:
        return dt.strftime("%d.%m.%Y")


class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[str, list[WebSocket]] = {}
        self.user_connections: dict[int, set[str]] = {}  # user_id -> set of room_ids
        self.online_users: set[int] = set()  # Множество онлайн пользователей

    async def connect(self, websocket: WebSocket, room_id: str, user_id: int):
        await websocket.accept()
        
        if room_id not in self.active_connections:
            self.active_connections[room_id] = []
        self.active_connections[room_id].append(websocket)
        
        if user_id not in self.user_connections:
            self.user_connections[user_id] = set()
        self.user_connections[user_id].add(room_id)
        
        # Пользователь онлайн
        self.online_users.add(user_id)
        await self._update_user_online_status(user_id, True)

    def disconnect(self, websocket: WebSocket, room_id: str, user_id: int):
        if room_id in self.active_connections:
            if websocket in self.active_connections[room_id]:
                self.active_connections[room_id].remove(websocket)
            if not self.active_connections[room_id]:
                del self.active_connections[room_id]
        
        if user_id in self.user_connections:
            self.user_connections[user_id].discard(room_id)
            
            if not self.user_connections[user_id]:
                del self.user_connections[user_id]
                self.online_users.discard(user_id)
                import asyncio
                asyncio.create_task(self._update_user_online_status(user_id, False))

    async def _update_user_online_status(self, user_id: int, is_online: bool):
        """Обновить статус пользователя в БД"""
        async with async_session_factory() as session:
            query = select(User).where(User.id == user_id)
            result = await session.execute(query)
            user = result.scalar_one_or_none()
            
            if user:
                user.is_online = is_online
                if not is_online:
                    user.last_seen = datetime.utcnow()
                await session.commit()

    async def broadcast(self, message: str, room_id: str):
        if room_id in self.active_connections:
            dead_connections = []
            for connection in self.active_connections[room_id]:
                try:
                    await connection.send_text(message)
                except Exception:
                    dead_connections.append(connection)
            
            for conn in dead_connections:
                if conn in self.active_connections[room_id]:
                    self.active_connections[room_id].remove(conn)

    def is_user_online(self, user_id: int) -> bool:
        return user_id in self.online_users

    def get_online_users_in_room(self, room_id: str) -> list[int]:
        """Получить список онлайн пользователей в комнате"""
        online = []
        for user_id, rooms in self.user_connections.items():
            if room_id in rooms:
                online.append(user_id)
        return online


manager = ConnectionManager()



@app.post("/register", response_model=UserResponse)
async def register_user(user_data: UserCreate):
    """Регистрация нового пользователя"""
    async with async_session_factory() as session:
        # Проверяем существование
        query = select(User).where(
            or_(
                User.username == user_data.username,
                User.email == user_data.email
            )
        )
        result = await session.execute(query)
        existing = result.scalar_one_or_none()
        
        if existing:
            if existing.username == user_data.username:
                raise HTTPException(status_code=400, detail="Никнейм уже занят")
            raise HTTPException(status_code=400, detail="Email уже используется")
        
        hashed_pwd = get_password_hash(user_data.password)
        new_user = User(
            username=user_data.username,
            email=user_data.email,
            hashed_password=hashed_pwd
        )
        session.add(new_user)
        await session.commit()
        await session.refresh(new_user)
        
        return new_user


@app.post("/login", response_model=Token)
async def login(login_data: UserLogin):
    """Вход в аккаунт"""
    async with async_session_factory() as session:
        query = select(User).where(User.email == login_data.email)
        result = await session.execute(query)
        user = result.scalar_one_or_none()
        
        if not user or not verify_password(login_data.password, user.hashed_password):
            raise HTTPException(status_code=401, detail="Неверная почта или пароль")
        
        user.is_online = True
        user.last_seen = datetime.utcnow()
        await session.commit()
        
        access_token = create_access_token(data={
            "sub": str(user.id),
            "username": user.username
        })
        
        return {"access_token": access_token, "token_type": "bearer"}



@app.get("/me", response_model=UserResponse)
async def get_me(current_user: dict = Depends(get_current_user)):
    """Получить свой профиль"""
    async with async_session_factory() as session:
        query = select(User).where(User.id == current_user["id"])
        result = await session.execute(query)
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(status_code=404, detail="Пользователь не найден")
        
        return user


@app.post("/me/avatar")
async def update_avatar(
    data: UpdateAvatar,
    current_user: dict = Depends(get_current_user)
):
    """Обновить аватар"""
    async with async_session_factory() as session:
        query = select(User).where(User.id == current_user["id"])
        result = await session.execute(query)
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(status_code=404, detail="Пользователь не найден")
        
        user.avatar_url = data.avatar_url
        await session.commit()
        
        return {"status": "ok", "avatar_url": user.avatar_url}


@app.patch("/me")
async def update_profile(
    data: UpdateProfile,
    current_user: dict = Depends(get_current_user)
):
    """Обновить профиль"""
    async with async_session_factory() as session:
        query = select(User).where(User.id == current_user["id"])
        result = await session.execute(query)
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(status_code=404, detail="Пользователь не найден")
        
        if data.username:
            check = select(User).where(
                and_(User.username == data.username, User.id != user.id)
            )
            if (await session.execute(check)).scalar_one_or_none():
                raise HTTPException(status_code=400, detail="Никнейм уже занят")
            user.username = data.username
        
        if data.status is not None:
            user.status = data.status
        
        await session.commit()
        
        return {"status": "ok"}

@app.get("/users/{user_id}/status")
async def get_user_status(
    user_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Получить статус пользователя"""
    is_online = manager.is_user_online(user_id)
    
    if is_online:
        return {"is_online": True, "last_seen": None}
    
    async with async_session_factory() as session:
        query = select(User).where(User.id == user_id)
        result = await session.execute(query)
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(status_code=404, detail="Пользователь не найден")
        
        return {
            "is_online": False,
            "last_seen": user.last_seen.isoformat() if user.last_seen else None
        }

@app.post("/chats/{chat_id}/read")
async def mark_messages_read(
    chat_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Отметить сообщения как прочитанные"""
    my_id = current_user["id"]
    
    async with async_session_factory() as session:
        chat_query = select(DirectChat).where(
            and_(
                DirectChat.id == chat_id,
                or_(
                    DirectChat.user1_id == my_id,
                    DirectChat.user2_id == my_id
                )
            )
        )
        chat_result = await session.execute(chat_query)
        chat = chat_result.scalar_one_or_none()
        
        if not chat:
            raise HTTPException(status_code=404, detail="Чат не найден")
        
        await session.execute(
            Message.__table__.update()
            .where(
                and_(
                    Message.chat_id == chat_id,
                    Message.sender_id != my_id,
                    Message.is_read == False
                )
            )
            .values(is_read=True)
        )
        await session.commit()
        
        room_id = f"dm_{chat_id}"
        read_notification = json.dumps({
            "type": "messages_read",
            "chat_id": chat_id,
            "reader_id": my_id
        })
        await manager.broadcast(read_notification, room_id)
        
        return {"status": "ok"}
    


@app.get("/users/search")
async def search_users(
    q: str,
    current_user: dict = Depends(get_current_user)
):
    """Поиск пользователей по никнейму"""
    async with async_session_factory() as session:
        query = select(User).where(
            and_(
                User.username.ilike(f"%{q}%"),
                User.id != current_user["id"]
            )
        ).limit(20)
        
        result = await session.execute(query)
        users = result.scalars().all()
        
        return [
            {
                "id": u.id,
                "username": u.username,
                "avatar_url": u.avatar_url,
                "is_online": manager.is_user_online(u.id)
            }
            for u in users
        ]


@app.get("/me/directs")
async def get_my_direct_chats(current_user: dict = Depends(get_current_user)):
    """Получить список личных чатов"""
    my_id = current_user["id"]
    
    async with async_session_factory() as session:
        query = select(DirectChat).where(
            or_(
                DirectChat.user1_id == my_id,
                DirectChat.user2_id == my_id
            )
        )
        result = await session.execute(query)
        chats = result.scalars().all()
        
        response = []
        for chat in chats:
            friend_id = chat.user2_id if chat.user1_id == my_id else chat.user1_id
            
            friend_query = select(User).where(User.id == friend_id)
            friend_result = await session.execute(friend_query)
            friend = friend_result.scalar_one()
            
            last_msg_query = select(Message).where(
                Message.chat_id == chat.id
            ).order_by(Message.created_at.desc()).limit(1)
            last_msg_result = await session.execute(last_msg_query)
            last_msg = last_msg_result.scalar_one_or_none()
            
            unread_query = select(func.count(Message.id)).where(
                and_(
                    Message.chat_id == chat.id,
                    Message.sender_id != my_id,
                    Message.is_read == False
                )
            )
            unread_result = await session.execute(unread_query)
            unread_count = unread_result.scalar() or 0
            
            response.append({
                "id": chat.id,
                "name": friend.username,
                "username": friend.username,
                "avatar_url": friend.avatar_url,
                "is_online": manager.is_user_online(friend_id),
                "last_message": last_msg.text if last_msg else None,
                "time": format_time(last_msg.created_at) if last_msg else None,
                "unread_count": unread_count
            })
        
        response.sort(
            key=lambda x: x["time"] if x["time"] else "",
            reverse=True
        )
        
        return response


@app.post("/direct/start")
async def start_direct_chat(
    target_user_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Начать личный чат с пользователем"""
    my_id = current_user["id"]
    
    if target_user_id == my_id:
        raise HTTPException(status_code=400, detail="Нельзя создать чат с собой")
    
    async with async_session_factory() as session:
        target_query = select(User).where(User.id == target_user_id)
        target_result = await session.execute(target_query)
        target_user = target_result.scalar_one_or_none()
        
        if not target_user:
            raise HTTPException(status_code=404, detail="Пользователь не найден")
        
        chat_query = select(DirectChat).where(
            or_(
                and_(DirectChat.user1_id == my_id, DirectChat.user2_id == target_user_id),
                and_(DirectChat.user1_id == target_user_id, DirectChat.user2_id == my_id)
            )
        )
        chat_result = await session.execute(chat_query)
        existing_chat = chat_result.scalar_one_or_none()
        
        if existing_chat:
            return {
                "id": existing_chat.id,
                "is_new": False,
                "name": target_user.username,
                "avatar_url": target_user.avatar_url
            }
        
        new_chat = DirectChat(user1_id=my_id, user2_id=target_user_id)
        session.add(new_chat)
        await session.commit()
        await session.refresh(new_chat)
        
        return {
            "id": new_chat.id,
            "is_new": True,
            "name": target_user.username,
            "avatar_url": target_user.avatar_url
        }


@app.get("/chats/{chat_id}/messages")
async def get_chat_messages(
    chat_id: int,
    limit: int = 50,
    offset: int = 0,
    current_user: dict = Depends(get_current_user)
):
    """Получить историю сообщений чата"""
    my_id = current_user["id"]
    
    async with async_session_factory() as session:
        chat_query = select(DirectChat).where(
            and_(
                DirectChat.id == chat_id,
                or_(
                    DirectChat.user1_id == my_id,
                    DirectChat.user2_id == my_id
                )
            )
        )
        chat_result = await session.execute(chat_query)
        chat = chat_result.scalar_one_or_none()
        
        if not chat:
            raise HTTPException(status_code=404, detail="Чат не найден")
        
        messages_query = (
            select(Message, User)
            .join(User, Message.sender_id == User.id)
            .where(Message.chat_id == chat_id)
            .order_by(Message.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        
        result = await session.execute(messages_query)
        messages = result.all()
        
        return [
            {
                "id": msg.id,
                "chat_id": msg.chat_id,
                "sender_id": msg.sender_id,
                "username": user.username,
                "user_avatar": user.avatar_url,
                "text": msg.text,
                "image": msg.image_url,
                "time": msg.created_at.strftime("%H:%M"),
                "is_read": msg.is_read
            }
            for msg, user in reversed(messages)
        ]

@app.post("/games/create")
async def create_game(
    game_type: str,
    chat_id: int = None,
    group_id: int = None,
    current_user: dict = Depends(get_current_user)
):
    """Создать игровую сессию"""
    if game_type not in GAME_TYPES:
        raise HTTPException(status_code=400, detail="Неизвестный тип игры")
    
    if not chat_id and not group_id:
        raise HTTPException(status_code=400, detail="Укажите chat_id или group_id")
    
    async with async_session_factory() as session:
        new_game = GameSession(
            game_type=game_type,
            chat_id=chat_id,
            group_id=group_id,
            creator_id=current_user["id"],
            status="waiting"
        )
        session.add(new_game)
        await session.commit()
        await session.refresh(new_game)
        
        player = GamePlayer(
            session_id=new_game.id,
            user_id=current_user["id"]
        )
        session.add(player)
        await session.commit()
        
        return {
            "id": new_game.id,
            "game_type": game_type,
            "status": "waiting",
            "creator": current_user["username"]
        }


@app.post("/games/{session_id}/join")
async def join_game(
    session_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Присоединиться к игре"""
    async with async_session_factory() as session:
        query = select(GameSession).where(GameSession.id == session_id)
        result = await session.execute(query)
        game = result.scalar_one_or_none()
        
        if not game:
            raise HTTPException(status_code=404, detail="Игра не найдена")
        
        if game.status != "waiting":
            raise HTTPException(status_code=400, detail="Игра уже началась или завершена")
        
        check_query = select(GamePlayer).where(
            and_(
                GamePlayer.session_id == session_id,
                GamePlayer.user_id == current_user["id"]
            )
        )
        if (await session.execute(check_query)).scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Вы уже в игре")
        
        player = GamePlayer(
            session_id=session_id,
            user_id=current_user["id"]
        )
        session.add(player)
        await session.commit()
        
        return {"status": "joined", "session_id": session_id}


@app.post("/games/{session_id}/start")
async def start_game(
    session_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Начать игру"""
    async with async_session_factory() as session:
        query = select(GameSession).where(GameSession.id == session_id)
        result = await session.execute(query)
        game = result.scalar_one_or_none()
        
        if not game:
            raise HTTPException(status_code=404, detail="Игра не найдена")
        
        if game.creator_id != current_user["id"]:
            raise HTTPException(status_code=403, detail="Только создатель может начать игру")
        
        game.status = "active"
        await session.commit()
        
        return {"status": "active", "session_id": session_id}


@app.post("/games/{session_id}/action")
async def game_action(
    session_id: int,
    action: str,
    data: dict = None,
    current_user: dict = Depends(get_current_user)
):
    """Действие в игре (бросить кубик, выбрать вариант и т.д.)"""
    async with async_session_factory() as session:
        query = select(GameSession).where(GameSession.id == session_id)
        result = await session.execute(query)
        game = result.scalar_one_or_none()
        
        if not game:
            raise HTTPException(status_code=404, detail="Игра не найдена")
        
        if game.status != "active":
            raise HTTPException(status_code=400, detail="Игра не активна")
        
        response = {}
        
        if game.game_type == "dice" and action == "roll":
            roll_result = random.randint(1, 6)
            
            player_query = select(GamePlayer).where(
                and_(
                    GamePlayer.session_id == session_id,
                    GamePlayer.user_id == current_user["id"]
                )
            )
            player_result = await session.execute(player_query)
            player = player_result.scalar_one()
            player.score = roll_result
            await session.commit()
            
            response = {
                "action": "roll",
                "result": roll_result,
                "user": current_user["username"]
            }
        
        elif game.game_type == "wheel" and action == "spin":
            options = data.get("options", [])
            if not options:
                raise HTTPException(status_code=400, detail="Нет вариантов для колеса")
            
            result = random.choice(options)
            response = {
                "action": "spin",
                "result": result,
                "options": options
            }
        
        elif game.game_type == "rps" and action == "choose":
            choice = data.get("choice")
            if choice not in ["rock", "paper", "scissors"]:
                raise HTTPException(status_code=400, detail="Неверный выбор")
            
            response = {
                "action": "choose",
                "user": current_user["username"],
                "choice": choice
            }
        
        elif game.game_type == "random" and action == "pick":
            players_query = select(GamePlayer, User).join(User).where(
                GamePlayer.session_id == session_id
            )
            players_result = await session.execute(players_query)
            players = players_result.all()
            
            if players:
                winner = random.choice(players)
                response = {
                    "action": "pick",
                    "result": winner[1].username
                }
        
        return response


@app.post("/games/{session_id}/end")
async def end_game(
    session_id: int,
    winner_id: int = None,
    current_user: dict = Depends(get_current_user)
):
    """Завершить игру"""
    async with async_session_factory() as session:
        query = select(GameSession).where(GameSession.id == session_id)
        result = await session.execute(query)
        game = result.scalar_one_or_none()
        
        if not game:
            raise HTTPException(status_code=404, detail="Игра не найдена")
        
        game.status = "finished"
        game.finished_at = datetime.utcnow()

        players_query = select(GamePlayer).where(GamePlayer.session_id == session_id)
        players_result = await session.execute(players_query)
        players = players_result.scalars().all()
        
        for player in players:
            stats_query = select(GameStats).where(
                and_(
                    GameStats.user_id == player.user_id,
                    GameStats.game_type == game.game_type
                )
            )
            stats_result = await session.execute(stats_query)
            stats = stats_result.scalar_one_or_none()
            
            if not stats:
                stats = GameStats(
                    user_id=player.user_id,
                    game_type=game.game_type
                )
                session.add(stats)
            
            stats.games_played += 1
            stats.total_score += player.score
            
            if player.score > stats.best_score:
                stats.best_score = player.score
            
            if winner_id and player.user_id == winner_id:
                player.is_winner = True
                stats.games_won += 1
        
        await session.commit()
        
        return {"status": "finished", "session_id": session_id}


@app.get("/games/stats")
async def get_my_game_stats(current_user: dict = Depends(get_current_user)):
    """Получить свою статистику"""
    async with async_session_factory() as session:
        query = select(GameStats).where(GameStats.user_id == current_user["id"])
        result = await session.execute(query)
        stats = result.scalars().all()
        
        return [
            {
                "game_type": s.game_type,
                "games_played": s.games_played,
                "games_won": s.games_won,
                "win_rate": round(s.games_won / s.games_played * 100, 1) if s.games_played > 0 else 0,
                "total_score": s.total_score,
                "best_score": s.best_score
            }
            for s in stats
        ]


@app.get("/games/stats/{user_id}")
async def get_user_game_stats(
    user_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Получить статистику пользователя"""
    async with async_session_factory() as session:
        query = select(GameStats).where(GameStats.user_id == user_id)
        result = await session.execute(query)
        stats = result.scalars().all()
        
        return [
            {
                "game_type": s.game_type,
                "games_played": s.games_played,
                "games_won": s.games_won,
                "win_rate": round(s.games_won / s.games_played * 100, 1) if s.games_played > 0 else 0,
                "best_score": s.best_score
            }
            for s in stats
        ]


@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    """Загрузить файл (изображение)"""
    allowed_types = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="Разрешены только изображения")
        
    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Файл слишком большой (макс. 10MB)")
    
    file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = f"uploads/{unique_filename}"
    
    with open(file_path, "wb") as buffer:
        buffer.write(contents)
    
    return {"url": f"/uploads/{unique_filename}"}


@app.websocket("/ws/dm/{chat_id}")
async def websocket_dm(
    websocket: WebSocket,
    chat_id: int,
    token: str = Query(...)
):
    """WebSocket для личных сообщений"""
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = int(payload.get("sub"))
        username = payload.get("username")
    except Exception:
        await websocket.close(code=4001)
        return
    
    async with async_session_factory() as session:
        chat_query = select(DirectChat).where(
            and_(
                DirectChat.id == chat_id,
                or_(
                    DirectChat.user1_id == user_id,
                    DirectChat.user2_id == user_id
                )
            )
        )
        result = await session.execute(chat_query)
        chat = result.scalar_one_or_none()
        
        if not chat:
            await websocket.close(code=4003)
            return
    
    room_id = f"dm_{chat_id}"
    await manager.connect(websocket, room_id, user_id)
    
    try:
        async with async_session_factory() as session:
            query = (
                select(Message, User)
                .join(User, Message.sender_id == User.id)
                .where(Message.chat_id == chat_id)
                .order_by(Message.created_at.desc())
                .limit(50)
            )
            result = await session.execute(query)
            messages = list(reversed(result.all()))
            
            for msg, user in messages:
                history_data = json.dumps({
                    "id": msg.id,
                    "username": user.username,
                    "user_avatar": user.avatar_url,
                    "text": msg.text,
                    "image": msg.image_url,
                    "time": msg.created_at.strftime("%H:%M"),
                    "chat_id": chat_id,
                    "sender_id": msg.sender_id,
                    "is_read": msg.is_read
                })
                await websocket.send_text(history_data)
        
        
        while True:
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            msg_type = message_data.get("type", "message")
            
            if msg_type == "read":
                async with async_session_factory() as session:
                    await session.execute(
                        Message.__table__.update()
                        .where(
                            and_(
                                Message.chat_id == chat_id,
                                Message.sender_id != user_id,
                                Message.is_read == False
                            )
                        )
                        .values(is_read=True)
                    )
                    await session.commit()
                
                read_notification = json.dumps({
                    "type": "messages_read",
                    "chat_id": chat_id,
                    "reader_id": user_id
                })
                await manager.broadcast(read_notification, room_id)
                continue
            
            text = message_data.get("text", "").strip()
            image_url = message_data.get("image")
            
            if not text and not image_url:
                continue
            
            async with async_session_factory() as session:
                user_query = select(User).where(User.id == user_id)
                user_result = await session.execute(user_query)
                sender = user_result.scalar_one()
                
                new_msg = Message(
                    chat_id=chat_id,
                    sender_id=user_id,
                    text=text if text else None,
                    image_url=image_url,
                    is_read=False
                )
                session.add(new_msg)
                await session.commit()
                await session.refresh(new_msg)
                
                response_data = json.dumps({
                    "id": new_msg.id,
                    "username": sender.username,
                    "user_avatar": sender.avatar_url,
                    "text": text,
                    "image": image_url,
                    "time": datetime.utcnow().strftime("%H:%M"),
                    "chat_id": chat_id,
                    "sender_id": user_id,
                    "is_read": False
                })
                await manager.broadcast(response_data, room_id)
    
    except WebSocketDisconnect:
        manager.disconnect(websocket, room_id, user_id)
    except Exception as e:
        print(f"WebSocket error: {e}")
        manager.disconnect(websocket, room_id, user_id)


