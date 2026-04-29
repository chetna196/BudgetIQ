
CREATE TABLE users(
    user_id INT PRIMARY KEY,
    name VARCHAR(60) NOT NULL
);

INSERT INTO users VALUES
(241,'Gauri'),
(242,'Namita'),
(243,'Anupriya'),
(244,'Phulesh'),
(245,'Mayur'),
(246,'Aditya');
                                                                                                            

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO categories VALUES
(11, 'Food'),
(12, 'Shopping'),
(13, 'Rent'),
(14, 'Travel'),
(15, 'Salary');



CREATE TABLE transactions(
    transaction_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) CHECK (amount > 0),
    date DATE NOT NULL,
    category_id INT,
    type VARCHAR(10) CHECK (type IN ('debit','credit')),

    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);



CREATE OR REPLACE FUNCTION check_balance()
RETURNS TRIGGER AS $$
DECLARE total_balance DECIMAL(10,2);
BEGIN
    SELECT 
    COALESCE(SUM(CASE WHEN type='credit' THEN amount ELSE 0 END),0) -
    COALESCE(SUM(CASE WHEN type='debit' THEN amount ELSE 0 END),0)
    INTO total_balance
    FROM transactions
    WHERE user_id = NEW.user_id;

    IF NEW.type = 'debit' AND NEW.amount > total_balance THEN
        RAISE EXCEPTION 'Insufficient balance!';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_balance
BEFORE INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION check_balance();



CREATE TABLE transaction_log(
    log_id SERIAL PRIMARY KEY,
    transaction_id INT,
    action VARCHAR(20),
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE OR REPLACE FUNCTION log_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO transaction_log(transaction_id, action)
    VALUES (NEW.transaction_id, 'INSERT');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_insert
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION log_insert();


INSERT INTO transactions VALUES
(1, 241, 10000, '2026-04-01', 15, 'credit'),
(2, 241, 500, '2026-04-02', 11, 'debit'),
(3, 241, 1500, '2026-04-03', 12, 'debit'),
(4, 242, 20000, '2026-04-01', 15, 'credit'),
(5, 242, 5000, '2026-04-05', 13, 'debit'),
(6, 242, 2000, '2026-04-10', 14, 'debit'),
(7, 243, 15000, '2026-04-01', 15, 'credit'),
(8, 243, 3000, '2026-04-06', 12, 'debit'),
(9, 243, 1200, '2026-04-07', 11, 'debit'),
(10, 244, 18000, '2026-04-02', 15, 'credit'),
(11, 244, 4000, '2026-04-08', 13, 'debit'),
(12, 244, 1500, '2026-04-12', 14, 'debit'),
(13, 245, 22000, '2026-04-01', 15, 'credit'),
(14, 245, 2500, '2026-04-09', 11, 'debit'),
(15, 245, 3500, '2026-04-15', 12, 'debit'),
(16, 246, 17000, '2026-04-03', 15, 'credit'),
(17, 246, 2000, '2026-04-10', 14, 'debit'),
(18, 246, 1000, '2026-04-20', 11, 'debit');




SELECT user_id, date, COUNT(*) AS transaction_count
FROM transactions
GROUP BY user_id, date
HAVING COUNT(*) >= 2;


SELECT user_id, SUM(amount) AS total_spent
FROM transactions
WHERE date >= '2026-04-10' AND type='debit'
GROUP BY user_id;


SELECT user_id,
SUM(CASE WHEN type='credit' THEN amount ELSE 0 END) -
SUM(CASE WHEN type='debit' THEN amount ELSE 0 END) AS balance
FROM transactions
GROUP BY user_id;


SELECT t.user_id, c.category_name, SUM(t.amount) AS total
FROM transactions t
INNER JOIN categories c
ON t.category_id = c.category_id
WHERE t.type='debit'
GROUP BY t.user_id, c.category_name;
