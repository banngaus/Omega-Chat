import asyncio
from database import engine, Base
from models import Message, User

async def create_tables():
    print("Подключаюсь к базе и создаю таблицы...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("ВСЁ! Таблицы созданы. Ура")

if __name__ == "__main__":
    asyncio.run(create_tables())