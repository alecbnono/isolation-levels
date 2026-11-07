-- 00_schema.sql  (standalone: Sakila does NOT need to be loaded)
-- `customer` is a simplified copy of sakila.customer (9 cols -> 5 cols; store/address FKs,
-- create_date and last_update dropped). Rows are the real Sakila customers 1-5.

DROP DATABASE IF EXISTS stadvdb_ho3;
CREATE DATABASE stadvdb_ho3;
USE stadvdb_ho3;

CREATE TABLE customer (
    customer_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name  VARCHAR(45) NOT NULL,
    last_name   VARCHAR(45) NOT NULL,
    email       VARCHAR(50) DEFAULT NULL,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO customer (customer_id, first_name, last_name, email, active) VALUES
(1, 'MARY',      'SMITH',    'MARY.SMITH@sakilacustomer.org',           1),
(2, 'PATRICIA',  'JOHNSON',  'PATRICIA.JOHNSON@sakilacustomer.org',     1),
(3, 'LINDA',     'WILLIAMS', 'LINDA.WILLIAMS@sakilacustomer.org',       1),
(4, 'BARBARA',   'JONES',    'BARBARA.JONES@sakilacustomer.org',        1),
(5, 'ELIZABETH', 'BROWN',    'ELIZABETH.BROWN@sakilacustomer.org',      1);

CREATE TABLE accounts (
    account_id  INT PRIMARY KEY AUTO_INCREMENT,
    customer_id SMALLINT UNSIGNED NOT NULL,
    balance     DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    status      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
) ENGINE=InnoDB;

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    account_id     INT NOT NULL,
    type           VARCHAR(20) NOT NULL,   -- 'DEPOSIT', 'WITHDRAWAL', 'TRANSFER'
    amount         DECIMAL(10, 2) NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
) ENGINE=InnoDB;
