CREATE DATABASE OnlineAuctionDB;
USE OnlineAuctionDB;

-- 1. Create Users Table
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Create Items Table
CREATE TABLE Items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    seller_id INT NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    FOREIGN KEY (seller_id) REFERENCES Users(user_id) 
        ON DELETE CASCADE
);

-- 3. Create Auctions Table
CREATE TABLE Auctions (
    auction_id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    starting_price DECIMAL(10, 2) NOT NULL,
    status ENUM('Open', 'Closed') DEFAULT 'Open',
    FOREIGN KEY (item_id) REFERENCES Items(item_id)
);

-- 4. Create Bids Table
CREATE TABLE Bids (
    bid_id INT AUTO_INCREMENT PRIMARY KEY,
    auction_id INT NOT NULL,
    bidder_id INT NOT NULL,
    bid_amount DECIMAL(10, 2) NOT NULL,
    bid_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (auction_id) REFERENCES Auctions(auction_id),
    FOREIGN KEY (bidder_id) REFERENCES Users(user_id)
);

-- 1. Insert Users (The Buyers and Sellers)
INSERT INTO Users (username, email) VALUES 
('Alice_Seller', 'alice@example.com'),
('Bob_Bidder', 'bob@example.com'),
('Charlie_Bidder', 'charlie@example.com');

-- 2. Insert an Item (Alice wants to sell a Vintage Camera)
-- We assume Alice is user_id 1
INSERT INTO Items (seller_id, item_name, description, category) VALUES 
(1, 'Vintage 1950s Camera', 'A rare collectible film camera in working condition.', 'Electronics');

-- 3. Start an Auction for that Item
-- item_id is 1, starting price is 100.00
INSERT INTO Auctions (item_id, start_time, end_time, starting_price, status) VALUES 
(1, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), 100.00, 'Open');

SELECT * FROM Users;

-- Bob bids 150
INSERT INTO Bids (auction_id, bidder_id, bid_amount) VALUES (1, 2, 150.00);

-- Charlie bids 200
INSERT INTO Bids (auction_id, bidder_id, bid_amount) VALUES (1, 3, 200.00);

SELECT 
    U.username AS Leading_Bidder, 
    B.bid_amount AS Highest_Bid,
    B.bid_time
FROM Bids B
JOIN Users U ON B.bidder_id = U.user_id
WHERE B.auction_id = 1
ORDER BY B.bid_amount DESC
LIMIT 1;

START TRANSACTION;

-- 1. We check the current highest bid first
-- 2. We 'Lock' the rows using FOR UPDATE to prevent others from bidding at this exact microsecond
SELECT MAX(bid_amount) FROM Bids WHERE auction_id = 1 FOR UPDATE;

-- 3. If our bid (250) is higher than the result above, we insert it
INSERT INTO Bids (auction_id, bidder_id, bid_amount) 
VALUES (1, 2, 250.00);

-- 4. If everything looks good, we save it permanently
COMMIT;

DELIMITER //

CREATE TRIGGER Before_Bid_Insert
BEFORE INSERT ON Bids
FOR EACH ROW
BEGIN
    DECLARE auction_status VARCHAR(20);

    -- Get the status of the auction for the bid being placed
    SELECT status INTO auction_status 
    FROM Auctions 
    WHERE auction_id = NEW.auction_id;

    -- If the auction is closed, cancel the insert and show an error
    IF auction_status = 'Closed' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot place bid: This auction is already closed.';
    END IF;
END //

DELIMITER ;

UPDATE Auctions SET status = 'Closed' WHERE auction_id = 1;

INSERT INTO Bids (auction_id, bidder_id, bid_amount) VALUES (1, 3, 300.00);