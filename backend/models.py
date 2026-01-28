from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base


class User(Base):
    """Пользователь"""
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    avatar_url = Column(String(500), nullable=True)
    status = Column(String(100), nullable=True)
    is_online = Column(Boolean, default=False)
    last_seen = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Связи
    sent_messages = relationship("Message", back_populates="sender", foreign_keys="Message.sender_id")
    game_stats = relationship("GameStats", back_populates="user")


class DirectChat(Base):
    """Личный чат между двумя пользователями"""
    __tablename__ = "direct_chats"
    
    id = Column(Integer, primary_key=True, index=True)
    user1_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    user2_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Связи
    user1 = relationship("User", foreign_keys=[user1_id])
    user2 = relationship("User", foreign_keys=[user2_id])
    messages = relationship("Message", back_populates="chat", cascade="all, delete-orphan")


class Message(Base):
    """Сообщение"""
    __tablename__ = 'messages'
    
    id = Column(Integer, primary_key=True, index=True)
    chat_id = Column(Integer, ForeignKey("direct_chats.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    text = Column(Text, nullable=True)
    image_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_read = Column(Boolean, default=False)
    
    # Связи
    chat = relationship("DirectChat", back_populates="messages")
    sender = relationship("User", back_populates="sent_messages", foreign_keys=[sender_id])


class GroupChat(Base):
    """Групповой чат"""
    __tablename__ = "group_chats"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    avatar_url = Column(String(500), nullable=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Связи
    owner = relationship("User", foreign_keys=[owner_id])
    members = relationship("GroupMember", back_populates="group", cascade="all, delete-orphan")


class GroupMember(Base):
    """Участник группового чата"""
    __tablename__ = "group_members"
    
    id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("group_chats.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    joined_at = Column(DateTime, default=datetime.utcnow)
    is_admin = Column(Boolean, default=False)
    
    # Связи
    group = relationship("GroupChat", back_populates="members")
    user = relationship("User")


# ============ ИГРЫ ============

class GameSession(Base):
    """Игровая сессия"""
    __tablename__ = 'game_sessions'
    
    id = Column(Integer, primary_key=True, index=True)
    game_type = Column(String(50), nullable=False)
    chat_id = Column(Integer, ForeignKey("direct_chats.id"), nullable=True)
    group_id = Column(Integer, ForeignKey("group_chats.id"), nullable=True)
    creator_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String(20), default="waiting")
    data = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    finished_at = Column(DateTime, nullable=True)
    
    # Связи
    creator = relationship("User", foreign_keys=[creator_id])
    players = relationship("GamePlayer", back_populates="session", cascade="all, delete-orphan")


class GamePlayer(Base):
    """Участник игры"""
    __tablename__ = 'game_players'
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("game_sessions.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    score = Column(Integer, default=0)
    is_winner = Column(Boolean, default=False)
    
    # Связи
    session = relationship("GameSession", back_populates="players")
    user = relationship("User")


class GameStats(Base):
    """Статистика игрока"""
    __tablename__ = 'game_stats'
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    game_type = Column(String(50), nullable=False)
    games_played = Column(Integer, default=0)
    games_won = Column(Integer, default=0)
    total_score = Column(Integer, default=0)
    best_score = Column(Integer, default=0)
    
    # Связи
    user = relationship("User", back_populates="game_stats")