CREATE TABLE IF NOT EXISTS bronze.yelp_business (
    id BIGSERIAL PRIMARY KEY,
    raw_json JSONB NOT NULL,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.yelp_review (
    id BIGSERIAL PRIMARY KEY,
    raw_json JSONB NOT NULL,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.yelp_user (
    id BIGSERIAL PRIMARY KEY,
    raw_json JSONB NOT NULL,
    ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SET synchronous_commit = OFF;

\copy bronze.yelp_business(raw_json)
FROM :'DATA_PATH'/'BUSINESS_FILE'
WITH (FORMAT csv,
    DELIMITER E'\x01', 
    QUOTE E'\x02', 
    ESCAPE E'\x03', 
    ENCODING 'UTF8'
);

\copy bronze.yelp_review(raw_json)
FROM :'DATA_PATH'/'REVIEW_FILE'
WITH (FORMAT csv,
    DELIMITER E'\x01', 
    QUOTE E'\x02', 
    ESCAPE E'\x03', 
    ENCODING 'UTF8'
);

\copy bronze.yelp_user(raw_json)
FROM :'DATA_PATH'/'USER_FILE'
WITH (FORMAT csv,
    DELIMITER E'\x01', 
    QUOTE E'\x02', 
    ESCAPE E'\x03', 
    ENCODING 'UTF8'
);
