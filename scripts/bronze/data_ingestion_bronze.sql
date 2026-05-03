

SET synchronous_commit = OFF;

TRUNCATE TABLE bronze.yelp_business;
\copy bronze.yelp_business(raw_json) FROM 'C:/Users/juanm/Documents/Diplomatura Ciencia de datos/SQL/SQL Project/Datasets/Yelp JSON/yelp_academic_dataset_business.json' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02', ESCAPE E'\x03', ENCODING 'UTF8' );

TRUNCATE TABLE bronze.yelp_review;
\copy bronze.yelp_review(raw_json) FROM 'C:/Users/juanm/Documents/Diplomatura Ciencia de datos/SQL/SQL Project/Datasets/Yelp JSON/yelp_academic_dataset_review.json' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02', ESCAPE E'\x03', ENCODING 'UTF8');

TRUNCATE TABLE bronze.yelp_user;
\copy bronze.yelp_user(raw_json) FROM 'C:/Users/juanm/Documents/Diplomatura Ciencia de datos/SQL/SQL Project/Datasets/Yelp JSON/yelp_academic_dataset_user.json' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02', ESCAPE E'\x03', ENCODING 'UTF8');
