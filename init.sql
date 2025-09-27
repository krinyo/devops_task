CREATE DATABASE test_db1;
CREATE DATABASE commerce_db;

\c test_db1;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL
);

INSERT INTO users (username) VALUES ('alice'), ('bob');
