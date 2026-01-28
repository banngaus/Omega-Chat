from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional


# ============ АУТЕНТИФИКАЦИЯ ============

class UserCreate(BaseModel):
    """Регистрация пользователя"""
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)


class UserLogin(BaseModel):
    """Вход пользователя"""
    email: EmailStr
    password: str


class Token(BaseModel):
    """JWT токен"""
    access_token: str
    token_type: str = "bearer"


# ============ ПОЛЬЗОВАТЕЛЬ ============

class UserBase(BaseModel):
    """Базовая информация о пользователе"""
    id: int
    username: str
    avatar_url: Optional[str] = None

    class Config:
        from_attributes = True


class UserResponse(UserBase):
    """Полная информация о пользователе"""
    email: str
    status: Optional[str] = None
    is_online: bool = False
    last_seen: Optional[datetime] = None
    created_at: Optional[datetime] = None


class UserPublic(UserBase):
    """Публичная информация (для других пользователей)"""
    status: Optional[str] = None
    is_online: bool = False


class UpdateAvatar(BaseModel):
    """Обновление аватара"""
    avatar_url: str


class UpdateProfile(BaseModel):
    """Обновление профиля"""
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    status: Optional[str] = Field(None, max_length=100)


# ============ СООБЩЕНИЯ ============

class MessageCreate(BaseModel):
    """Создание сообщения"""
    text: Optional[str] = None
    image_url: Optional[str] = None


class MessageResponse(BaseModel):
    """Сообщение в ответе"""
    id: int
    chat_id: int
    sender_id: int
    username: str  # Имя отправителя
    user_avatar: Optional[str] = None  # Аватар отправителя
    text: Optional[str] = None
    image_url: Optional[str] = None
    created_at: datetime
    is_read: bool = False
    time: str  # Форматированное время "14:23"

    class Config:
        from_attributes = True


# ============ ЧАТЫ ============

class ChatCreate(BaseModel):
    """Создание чата по username"""
    username: str


class DirectChatResponse(BaseModel):
    """Личный чат в списке"""
    id: int
    name: str  # Имя собеседника
    username: str  # Username собеседника
    avatar_url: Optional[str] = None
    is_online: bool = False
    last_message: Optional[str] = None
    time: Optional[str] = None  # Время последнего сообщения
    unread_count: int = 0

    class Config:
        from_attributes = True


class ChatDetail(BaseModel):
    """Детали чата"""
    id: int
    user: UserPublic  # Собеседник
    created_at: datetime
    messages_count: int = 0

    class Config:
        from_attributes = True


# ============ ПОИСК ============

class UserSearchResult(BaseModel):
    """Результат поиска пользователя"""
    id: int
    username: str
    avatar_url: Optional[str] = None
    is_online: bool = False

    class Config:
        from_attributes = True


# ============ WEBSOCKET ============

class WSMessage(BaseModel):
    """Сообщение через WebSocket"""
    text: Optional[str] = None
    image: Optional[str] = None


class WSMessageResponse(BaseModel):
    """Ответ через WebSocket"""
    id: int
    username: str
    user_avatar: Optional[str] = None
    text: Optional[str] = None
    image: Optional[str] = None
    time: str
    chat_id: int