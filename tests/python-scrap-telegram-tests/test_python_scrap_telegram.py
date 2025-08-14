import os
from dotenv import load_dotenv
from telethon import TelegramClient
from telethon.tl.types import InputPeerChannel
import asyncio
import logging
from collections import namedtuple

# Load environment variables from .env file
load_dotenv()

api_id = os.getenv('API_ID')
api_hash = os.getenv('API_HASH')
TARGET_CHAT = 't.me/aarenda'

DOWNLOADS_DIR = 'downloads'
os.makedirs(DOWNLOADS_DIR, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/test-python_scrap-telegram.log"),  # Log to a file named app.log
        logging.StreamHandler()  # Also log to console
    ]
)

async def main():
    async with TelegramClient('anon', api_id, api_hash) as client:
        chat = await client.get_entity(TARGET_CHAT)
        if hasattr(chat, 'id'):
            peer = InputPeerChannel(
                channel_id=chat.id,
                access_hash=chat.access_hash
            )
        else:
            logging.info("Объект не является чатом")
            return

        CityOperation = namedtuple('CityOperation', ['city', 'operation'])
        reply_to_cities = {
            353079: CityOperation('budva', 'rent'),
            353077: CityOperation('bar', 'rent'),
            353081: CityOperation('herceg-novi', 'rent'),
            353498: CityOperation('kotor', 'rent'),
            353091: CityOperation('podgorica', 'rent'),
            353083: CityOperation('tivat', 'rent'),
            353113: CityOperation('north_of_montenegro', 'rent'),
            353080: CityOperation('budva', 'sell'),
            353078: CityOperation('bar', 'sell'),
            353082: CityOperation('herceg-novi', 'sell'),
            353499: CityOperation('kotor', 'sell'),
            353098: CityOperation('podgorica', 'sell'),
            353084: CityOperation('tivat', 'sell'),
            353113: CityOperation('north_of_montenegro', 'sell'),
            353085: CityOperation('ulcinj', 'rent-sell'),
            353174: CityOperation('cetinje', 'rent-sell'),
        }


        for topic_id, CityOperationInstance in reply_to_cities.items():
            folder_path = os.path.join(DOWNLOADS_DIR)
            folder_city_type_path = os.path.join(DOWNLOADS_DIR, CityOperationInstance.operation, CityOperationInstance.city)
            os.makedirs(folder_path, exist_ok=True)
            folder_postfix = ''
            async for message in client.iter_messages(peer, limit=5, reverse=False, reply_to=topic_id): # , add_offset=20
                if message.photo:
                    if folder_postfix == '':
                        folder_postfix = message.date.strftime("%Y%m%d%H%M%S")
                        folder_path = os.path.join(folder_city_type_path, folder_postfix)
                        os.makedirs(folder_path, exist_ok=True)

                    file_name = f'{message.id}.jpg'
                    file_path = os.path.join(folder_path, file_name)

                    if not os.path.exists(file_path):
                        file_path = await message.download_media(file=file_path)
                        logging.info("------------------------------------------------------------------------")
                        logging.info(f"Фото сохранено: {file_path}")
                        logging.info("------------------------------------------------------------------------")
                    else:
                        logging.info("------------------------------------------------------------------------")
                        logging.info(f"Файл уже существует: {file_path}")
                        logging.info("------------------------------------------------------------------------")
                if message.text:
                    folder_postfix = ''
                    logging.info("------------------------------------------------------------------------")
                    logging.info(f"Текст: {message.text[:300]}...")
                    logging.info("------------------------------------------------------------------------")

if __name__ == "__main__":
    asyncio.run(main())
