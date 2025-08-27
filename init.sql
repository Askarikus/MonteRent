-- Enable UUID generation (pgcrypto)
CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- Bootstrap schema for ScrappedAdEntity (PostgreSQL)
CREATE TABLE IF NOT EXISTS scrapped_ads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hash VARCHAR(255) NOT NULL,
  type_sell_or_rent VARCHAR(255) NOT NULL,
  city VARCHAR(255) NOT NULL,
  telegram_group_name VARCHAR(255) NOT NULL,
  subregion VARCHAR(255),
  message_text TEXT NOT NULL,
  message_corrected_text TEXT,
  price DOUBLE PRECISION,
  photo_path VARCHAR(255),
  latitude NUMERIC(9, 6),
  longitude NUMERIC(9, 6),
  address VARCHAR(255),
  published_at JSON NOT NULL,
  telegram_message_id INTEGER NOT NULL,
  telegram_topic_id INTEGER,
  telegram_user_id VARCHAR(32) NOT NULL,
  message_hashtags_entities JSON,
  message_phones_entities JSON,
  hashtags JSON,
  phones JSON,
  omitted_by_admin_at TIMESTAMP(0) WITHOUT TIME ZONE,
  is_search_ad BOOLEAN,
  area_square_meters DOUBLE PRECISION,
  created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

-- Helpful indexes (optional)
CREATE INDEX IF NOT EXISTS idx_scrapped_ads_hash ON scrapped_ads (hash);
CREATE INDEX IF NOT EXISTS idx_scrapped_ads_city ON scrapped_ads (city);
CREATE INDEX IF NOT EXISTS idx_scrapped_ads_type ON scrapped_ads (type_sell_or_rent);
