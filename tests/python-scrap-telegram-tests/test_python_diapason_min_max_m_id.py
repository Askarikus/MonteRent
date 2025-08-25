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

async def album_bounds(client, peer, anchor_id: int, expected_user_id: int | None = None, topic_id: int | None = None):
    m0 = await client.get_messages(peer, ids=anchor_id)
    if not m0:
        return None, None, None  # not found

    gid = getattr(m0, 'grouped_id', None)

    def msg_uid(m):
        try:
            fid = getattr(m, 'from_id', None)
            uid = getattr(fid, 'user_id', None)
        except Exception:
            uid = None
        if uid is None:
            uid = getattr(m, 'sender_id', None)
        return uid

    def in_topic(m, topic_id_val):
        if topic_id_val is None:
            return True
        r = getattr(m, 'reply_to', None)
        # В форум-чатах Telethon даёт reply_to.reply_to_msg_id (верх сообщения темы) и/или reply_to_top_id
        # Проверяем оба на всякий случай.
        rid = getattr(r, 'reply_to_msg_id', None)
        rtop = getattr(r, 'reply_to_top_id', None)
        return rid == topic_id_val or rtop == topic_id_val

    def by_expected_user(m, expected_uid):
        if expected_uid is None:
            return True
        return str(msg_uid(m)) == str(expected_uid)

    # Сначала валидируем anchor: если нужны фильтры — требуем их соблюдения
    if not in_topic(m0, topic_id) or not by_expected_user(m0, expected_user_id):
        # Анкер не соответствует заданным фильтрам — альбом для данных условий не найден
        return None, None, None

    if gid:
        ids = set([anchor_id])
        LB = anchor_id - 100
        UB = anchor_id + 100

        # older side: id < anchor_id
        async for m in client.iter_messages(
            peer,
            reverse=True,         # oldest -> newest
            min_id=LB,            # exclusive lower window
            max_id=anchor_id,     # exclusive upper (id < anchor)
        ):
            if getattr(m, 'grouped_id', None) == gid and in_topic(m, topic_id) and by_expected_user(m, expected_user_id):
                ids.add(m.id)

        # newer side: id > anchor_id
        async for m in client.iter_messages(
            peer,
            reverse=False,        # newest -> oldest (порядок не критичен)
            min_id=anchor_id,     # exclusive lower (id > anchor)
            max_id=UB,            # exclusive upper window
        ):
            if getattr(m, 'grouped_id', None) == gid and in_topic(m, topic_id) and by_expected_user(m, expected_user_id):
                ids.add(m.id)

        return (min(ids), anchor_id, max(ids)) if ids else (anchor_id, anchor_id, anchor_id)

    # Не альбом — одиночное сообщение; при необходимости фильтры уже проверены выше
    return anchor_id, anchor_id, anchor_id

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

        min_id, anchor_id, max_id = await album_bounds(client, peer, 2381060, expected_user_id=5965264111, topic_id=353077)

        logging.info("min_id: %s, anchor_id: %s, max_id: %s", min_id, anchor_id, max_id)

        # min_id = 2381140
        # topic_id = 353079
        # expected_user_id = 258018753
        # _start_id = min_id
        # _finish_id = None

        # for i in range(5):
        #     async for message in client.iter_messages(
        #         peer,
        #         reverse=False,
        #         reply_to=topic_id,
        #         min_id=min_id,
        #         max_id=min_id + i,
        #         wait_time=10,
        #     ):
        #         if expected_user_id is not None:
        #             try:
        #                 _from_id = getattr(message, 'from_id', None)
        #                 _uid = getattr(_from_id, 'user_id', None)
        #             except Exception:
        #                 _uid = None
        #             if _uid is None:
        #                 _uid = getattr(message, 'sender_id', None)
        #             current_uid = str(_uid) if _uid is not None else ''
        #             if current_uid != expected_user_id:
        #                 _start_id = getattr(message, 'id', 'n/a')
        #                 break
        #         if message.text:
        #             _start_id = getattr(message, 'id', 'n/a')
        #             break

        # for i in range(5):
        #     async for message in client.iter_messages(
        #         peer,
        #         reverse=False,
        #         reply_to=topic_id,
        #         min_id=min_id -1 - i,
        #         max_id=min_id + 1,
        #         wait_time=10,
        #     ):
        #         if expected_user_id is not None:
        #             try:
        #                 _from_id = getattr(message, 'from_id', None)
        #                 _uid = getattr(_from_id, 'user_id', None)
        #             except Exception:
        #                 _uid = None
        #             if _uid is None:
        #                 _uid = getattr(message, 'sender_id', None)
        #             current_uid = str(_uid) if _uid is not None else ''
        #             if current_uid != expected_user_id:
        #                 _finish_id = getattr(message, 'id', 'n/a')
        #                 break
        #         if message.text:
        #             _finish_id = getattr(message, 'id', 'n/a')
        #             break
                # logging.info("------------------------------------------------------------------------")
                # logging.info(message)
                # logging.info("------------------------------------------------------------------------")

        # logging.info("------------------------------------------------------------------------")
        # logging.info(_start_id)
        # logging.info(_finish_id)
        # logging.info("------------------------------------------------------------------------")

        async for message in client.iter_messages(
            peer,
            reverse=False,
            reply_to=353077,
            min_id=min_id - 1,
            max_id=max_id + 1,
            wait_time=10,
        ):

            folder_path = os.path.join(DOWNLOADS_DIR)
            if message.photo:
                os.makedirs(folder_path, exist_ok=True)
                file_name = f"{message.id}.jpg"
                file_path = os.path.join(folder_path, file_name)
                if not os.path.exists(file_path):
                    await message.download_media(file=file_path)
                    logging.info(f"Photo saved: {file_path}")

if __name__ == "__main__":
    asyncio.run(main())
