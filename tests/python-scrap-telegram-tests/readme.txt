при указании reverse=True
    async for message in client.iter_messages(peer, limit=20, reverse=True, reply_to=353079):

подгружаются варианты март 2024 года

//-----------
date_offset = datetime.date.fromtimestamp(1754904708) - время в UTC(точнее говоря, создается дата 2025-08-11 00:00:00)
соответственно
async for message in client.iter_messages(peer, limit=20, reverse=False, reply_to=353079, offset_date=date_offset):

загружаются только сообщения, созданные РАНЬШЕ 1754904708=2025-08-11 11:11 UTC
