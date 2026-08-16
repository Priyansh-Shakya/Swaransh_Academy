--* A config table containing only key-value pair fields all strings

CREATE TABLE config(
    key TEXT NOT NULL PRIMARY KEY,
    value TEXT NOT NULL
);
