-- Create and use database
CREATE DATABASE IF NOT EXISTS OnlineAuctionDB;
USE OnlineAuctionDB;

-- ============================================================================
-- SECTION 1: TABLE CREATION (NORMALIZED SCHEMA)
-- ============================================================================

-- 1. Users Table
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_email (email)
);

-- 2. Categories Table (Normalized from Items)
CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

-- 3. Items Table
CREATE TABLE Items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    seller_id INT NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE SET NULL,
    INDEX idx_seller (seller_id),
    INDEX idx_category (category_id)
);

-- 4. Auctions Table
CREATE TABLE Auctions (
    auction_id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    starting_price DECIMAL(10, 2) NOT NULL,
    reserve_price DECIMAL(10, 2),
    current_highest_bid DECIMAL(10, 2) DEFAULT 0.00,
    status ENUM('Open', 'Closed', 'Cancelled') DEFAULT 'Open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (item_id) REFERENCES Items(item_id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_end_time (end_time),
    INDEX idx_status_end_time (status, end_time)
);

-- 5. Bids Table
CREATE TABLE Bids (
    bid_id INT AUTO_INCREMENT PRIMARY KEY,
    auction_id INT NOT NULL,
    bidder_id INT NOT NULL,
    bid_amount DECIMAL(10, 2) NOT NULL,
    bid_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_winning BIT DEFAULT 0,
    FOREIGN KEY (auction_id) REFERENCES Auctions(auction_id) ON DELETE CASCADE,
    FOREIGN KEY (bidder_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    INDEX idx_auction_amount (auction_id, bid_amount DESC),
    INDEX idx_bidder (bidder_id),
    INDEX idx_bid_time (bid_time)
);

-- 6. Transactions Table
CREATE TABLE Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    auction_id INT NOT NULL,
    buyer_id INT NOT NULL,
    seller_id INT NOT NULL,
    final_price DECIMAL(10, 2) NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_status ENUM('Pending', 'Completed', 'Failed', 'Refunded') DEFAULT 'Pending',
    payment_method VARCHAR(50),
    shipping_status ENUM('Not Shipped', 'Shipped', 'Delivered') DEFAULT 'Not Shipped',
    FOREIGN KEY (auction_id) REFERENCES Auctions(auction_id),
    FOREIGN KEY (buyer_id) REFERENCES Users(user_id),
    FOREIGN KEY (seller_id) REFERENCES Users(user_id),
    INDEX idx_buyer (buyer_id),
    INDEX idx_seller (seller_id),
    INDEX idx_payment_status (payment_status)
);

-- 7. Audit Log Table (for tracking changes)
CREATE TABLE AuditLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action VARCHAR(20) NOT NULL,
    user_id INT,
    change_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT,
    INDEX idx_table_record (table_name, record_id),
    INDEX idx_timestamp (change_timestamp)
);

-- ============================================================================
-- SECTION 2: SAMPLE DATA INSERTION
-- ============================================================================

-- Insert Categories
INSERT INTO Categories (category_name, description) VALUES 
('Electronics', 'Electronic devices and gadgets'),
('Collectibles', 'Rare and collectible items'),
('Jewelry', 'Jewelry and precious stones'),
('Art', 'Paintings, sculptures, and artwork'),
('Antiques', 'Antique furniture and items');

-- Insert Users
INSERT INTO Users (username, email, phone, address) VALUES 
('Alice_Seller', 'alice@example.com', '555-0101', '123 Main St, New York'),
('Bob_Bidder', 'bob@example.com', '555-0102', '456 Oak Ave, Los Angeles'),
('Charlie_Bidder', 'charlie@example.com', '555-0103', '789 Pine Rd, Chicago'),
('Diana_Seller', 'diana@example.com', '555-0104', '321 Elm St, Houston'),
('Eve_Bidder', 'eve@example.com', '555-0105', '654 Maple Dr, Phoenix');

-- Insert Items
INSERT INTO Items (seller_id, item_name, description, category_id) VALUES 
(1, 'Vintage 1950s Camera', 'A rare collectible film camera in working condition', 1),
(1, 'Antique Pocket Watch', 'Gold plated pocket watch from 1920s', 2),
(4, 'Diamond Necklace', '2 carat diamond necklace with certificate', 3),
(4, 'Modern Art Painting', 'Abstract painting by emerging artist', 4),
(1, 'Victorian Writing Desk', 'Mahogany writing desk from Victorian era', 5);

-- Insert Auctions
INSERT INTO Auctions (item_id, start_time, end_time, starting_price, reserve_price, status) VALUES 
(1, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), 100.00, 200.00, 'Open'),
(2, NOW(), DATE_ADD(NOW(), INTERVAL 5 DAY), 50.00, 100.00, 'Open'),
(3, DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), 500.00, 800.00, 'Closed'),
(4, NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY), 200.00, 400.00, 'Open'),
(5, DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 8 DAY), 300.00, 500.00, 'Closed');

-- Insert Bids
INSERT INTO Bids (auction_id, bidder_id, bid_amount) VALUES 
-- Auction 1 (Vintage Camera)
(1, 2, 150.00),
(1, 3, 200.00),
(1, 2, 250.00),
(1, 5, 300.00),
-- Auction 2 (Pocket Watch)
(2, 3, 60.00),
(2, 5, 80.00),
-- Auction 3 (Diamond Necklace - Closed)
(3, 2, 600.00),
(3, 3, 750.00),
(3, 2, 900.00),
-- Auction 4 (Art Painting)
(4, 3, 250.00),
(4, 5, 300.00),
-- Auction 5 (Writing Desk - Closed)
(5, 2, 350.00),
(5, 3, 450.00),
(5, 2, 550.00);

-- Insert Transactions (for closed auctions)
INSERT INTO Transactions (auction_id, buyer_id, seller_id, final_price, payment_status, payment_method, shipping_status) VALUES 
(3, 2, 4, 900.00, 'Completed', 'Credit Card', 'Delivered'),
(5, 2, 1, 550.00, 'Completed', 'PayPal', 'Delivered');

-- ============================================================================
-- SECTION 3: TRIGGERS (FOR DATA INTEGRITY & ACID PROPERTIES)
-- ============================================================================

DELIMITER //

-- Trigger 1: Prevent bids on closed auctions
CREATE TRIGGER Before_Bid_Insert
BEFORE INSERT ON Bids
FOR EACH ROW
BEGIN
    DECLARE auction_status VARCHAR(20);
    DECLARE auction_end DATETIME;
    
    SELECT status, end_time INTO auction_status, auction_end
    FROM Auctions 
    WHERE auction_id = NEW.auction_id;
    
    IF auction_status = 'Closed' OR auction_status = 'Cancelled' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot place bid: This auction is closed or cancelled.';
    END IF;
    
    IF auction_end < NOW() THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot place bid: Auction time has expired.';
    END IF;
END //

-- Trigger 2: Update current highest bid after new bid
CREATE TRIGGER After_Bid_Insert
AFTER INSERT ON Bids
FOR EACH ROW
BEGIN
    UPDATE Auctions 
    SET current_highest_bid = NEW.bid_amount
    WHERE auction_id = NEW.auction_id 
    AND NEW.bid_amount > current_highest_bid;
    
    -- Mark this bid as winning, others as not winning
    UPDATE Bids 
    SET is_winning = 0 
    WHERE auction_id = NEW.auction_id;
    
    UPDATE Bids 
    SET is_winning = 1 
    WHERE bid_id = NEW.bid_id;
END //

-- Trigger 3: Audit log for auction status changes
CREATE TRIGGER After_Auction_Update
AFTER UPDATE ON Auctions
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO AuditLog (table_name, record_id, action, details)
        VALUES ('Auctions', NEW.auction_id, 'STATUS_CHANGE', 
                CONCAT('Status changed from ', OLD.status, ' to ', NEW.status));
    END IF;
END //

DELIMITER ;

-- ============================================================================
-- SECTION 4: STORED PROCEDURES
-- ============================================================================

DELIMITER //

-- Procedure 1: Place a bid with validation (demonstrates ACID transaction)
CREATE PROCEDURE PlaceBid(
    IN p_auction_id INT,
    IN p_bidder_id INT,
    IN p_bid_amount DECIMAL(10, 2)
)
BEGIN
    DECLARE v_current_highest DECIMAL(10, 2);
    DECLARE v_starting_price DECIMAL(10, 2);
    DECLARE v_auction_status VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bid placement failed. Transaction rolled back.';
    END;
    
    START TRANSACTION;
    
    -- Lock the auction row to prevent race conditions
    SELECT current_highest_bid, starting_price, status 
    INTO v_current_highest, v_starting_price, v_auction_status
    FROM Auctions 
    WHERE auction_id = p_auction_id
    FOR UPDATE;
    
    -- Validate bid amount
    IF p_bid_amount <= v_current_highest THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Bid must be higher than current highest bid.';
    END IF;
    
    IF p_bid_amount < v_starting_price THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Bid must be at least the starting price.';
    END IF;
    
    -- Insert the bid
    INSERT INTO Bids (auction_id, bidder_id, bid_amount)
    VALUES (p_auction_id, p_bidder_id, p_bid_amount);
    
    COMMIT;
    
    SELECT 'Bid placed successfully!' AS message;
END //

-- Procedure 2: Close auction and create transaction
CREATE PROCEDURE CloseAuction(IN p_auction_id INT)
BEGIN
    DECLARE v_winner_id INT;
    DECLARE v_highest_bid DECIMAL(10, 2);
    DECLARE v_seller_id INT;
    DECLARE v_reserve_price DECIMAL(10, 2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Auction closure failed.';
    END;
    
    START TRANSACTION;
    
    -- Get auction details
    SELECT I.seller_id, A.reserve_price, A.current_highest_bid
    INTO v_seller_id, v_reserve_price, v_highest_bid
    FROM Auctions A
    JOIN Items I ON A.item_id = I.item_id
    WHERE A.auction_id = p_auction_id
    FOR UPDATE;
    
    -- Get the winner (highest bidder)
    SELECT bidder_id INTO v_winner_id
    FROM Bids
    WHERE auction_id = p_auction_id
    ORDER BY bid_amount DESC
    LIMIT 1;
    
    -- Check if reserve price is met
    IF v_highest_bid >= IFNULL(v_reserve_price, 0) AND v_winner_id IS NOT NULL THEN
        -- Create transaction
        INSERT INTO Transactions (auction_id, buyer_id, seller_id, final_price, payment_status)
        VALUES (p_auction_id, v_winner_id, v_seller_id, v_highest_bid, 'Pending');
        
        -- Close the auction
        UPDATE Auctions 
        SET status = 'Closed' 
        WHERE auction_id = p_auction_id;
        
        SELECT 'Auction closed successfully with winner!' AS message, v_winner_id AS winner_id;
    ELSE
        -- Close auction without winner (reserve not met)
        UPDATE Auctions 
        SET status = 'Closed' 
        WHERE auction_id = p_auction_id;
        
        SELECT 'Auction closed - reserve price not met' AS message;
    END IF;
    
    COMMIT;
END //

-- Procedure 3: Get user statistics
CREATE PROCEDURE GetUserStats(IN p_user_id INT)
BEGIN
    SELECT 
        U.username,
        COUNT(DISTINCT I.item_id) AS items_sold,
        COUNT(DISTINCT B.bid_id) AS total_bids,
        COUNT(DISTINCT CASE WHEN B.is_winning = 1 AND A.status = 'Open' THEN B.bid_id END) AS currently_winning,
        COUNT(DISTINCT T1.transaction_id) AS purchases_made,
        COUNT(DISTINCT T2.transaction_id) AS items_sold_count,
        IFNULL(SUM(T1.final_price), 0) AS total_spent,
        IFNULL(SUM(T2.final_price), 0) AS total_earned
    FROM Users U
    LEFT JOIN Items I ON U.user_id = I.seller_id
    LEFT JOIN Bids B ON U.user_id = B.bidder_id
    LEFT JOIN Auctions A ON B.auction_id = A.auction_id
    LEFT JOIN Transactions T1 ON U.user_id = T1.buyer_id
    LEFT JOIN Transactions T2 ON U.user_id = T2.seller_id
    WHERE U.user_id = p_user_id
    GROUP BY U.user_id, U.username;
END //

DELIMITER ;

-- ============================================================================
-- SECTION 5: VIEWS (FOR SIMPLIFIED QUERIES)
-- ============================================================================

-- View 1: Active Auctions with Current Leader
CREATE VIEW ActiveAuctionsView AS
SELECT 
    A.auction_id,
    I.item_name,
    C.category_name,
    CONCAT(U.username) AS seller,
    A.starting_price,
    A.reserve_price,
    A.current_highest_bid,
    IFNULL(B.username, 'No bids yet') AS current_leader,
    A.end_time,
    TIMESTAMPDIFF(HOUR, NOW(), A.end_time) AS hours_remaining
FROM Auctions A
JOIN Items I ON A.item_id = I.item_id
JOIN Users U ON I.seller_id = U.user_id
LEFT JOIN Categories C ON I.category_id = C.category_id
LEFT JOIN (
    SELECT b1.auction_id, u.username
    FROM Bids b1
    JOIN Users u ON b1.bidder_id = u.user_id
    WHERE b1.is_winning = 1
) B ON A.auction_id = B.auction_id
WHERE A.status = 'Open' AND A.end_time > NOW();

-- View 2: Completed Transactions Summary
CREATE VIEW CompletedTransactionsView AS
SELECT 
    T.transaction_id,
    I.item_name,
    Buyer.username AS buyer,
    Seller.username AS seller,
    T.final_price,
    T.transaction_date,
    T.payment_status,
    T.shipping_status
FROM Transactions T
JOIN Auctions A ON T.auction_id = A.auction_id
JOIN Items I ON A.item_id = I.item_id
JOIN Users Buyer ON T.buyer_id = Buyer.user_id
JOIN Users Seller ON T.seller_id = Seller.user_id;

-- ============================================================================
-- SECTION 6: COMPLEX QUERIES (WITH JOINS, SUBQUERIES, AGGREGATES)
-- ============================================================================

-- Query 1: Find auction winners with total bids placed
SELECT 
    A.auction_id,
    I.item_name,
    Winner.username AS winner,
    B_win.bid_amount AS winning_bid,
    A.starting_price,
    (B_win.bid_amount - A.starting_price) AS price_increase,
    COUNT(B_all.bid_id) AS total_bids,
    COUNT(DISTINCT B_all.bidder_id) AS unique_bidders
FROM Auctions A
JOIN Items I ON A.item_id = I.item_id
JOIN Bids B_win ON A.auction_id = B_win.auction_id AND B_win.is_winning = 1
JOIN Users Winner ON B_win.bidder_id = Winner.user_id
LEFT JOIN Bids B_all ON A.auction_id = B_all.auction_id
WHERE A.status = 'Closed'
GROUP BY A.auction_id, I.item_name, Winner.username, B_win.bid_amount, A.starting_price
ORDER BY winning_bid DESC;

-- Query 2: Top sellers by revenue (with subquery)
SELECT 
    U.user_id,
    U.username,
    COUNT(T.transaction_id) AS items_sold,
    SUM(T.final_price) AS total_revenue,
    AVG(T.final_price) AS avg_sale_price,
    MAX(T.final_price) AS highest_sale
FROM Users U
JOIN Transactions T ON U.user_id = T.seller_id
WHERE T.payment_status = 'Completed'
GROUP BY U.user_id, U.username
HAVING total_revenue > (
    SELECT AVG(seller_revenue) 
    FROM (
        SELECT SUM(final_price) AS seller_revenue 
        FROM Transactions 
        WHERE payment_status = 'Completed'
        GROUP BY seller_id
    ) AS avg_revenues
)
ORDER BY total_revenue DESC;

-- Query 3: Bidding activity analysis with window functions simulation
SELECT 
    B.bidder_id,
    U.username,
    COUNT(B.bid_id) AS total_bids,
    SUM(CASE WHEN B.is_winning = 1 AND A.status = 'Open' THEN 1 ELSE 0 END) AS currently_winning,
    AVG(B.bid_amount) AS avg_bid_amount,
    MAX(B.bid_amount) AS highest_bid,
    COUNT(DISTINCT B.auction_id) AS auctions_participated
FROM Bids B
JOIN Users U ON B.bidder_id = U.user_id
JOIN Auctions A ON B.auction_id = A.auction_id
GROUP BY B.bidder_id, U.username
ORDER BY total_bids DESC;

-- Query 4: Category performance analysis
SELECT 
    C.category_name,
    COUNT(DISTINCT A.auction_id) AS total_auctions,
    COUNT(DISTINCT CASE WHEN A.status = 'Closed' THEN A.auction_id END) AS closed_auctions,
    AVG(A.current_highest_bid) AS avg_highest_bid,
    SUM(CASE WHEN A.status = 'Closed' THEN A.current_highest_bid ELSE 0 END) AS total_sales,
    COUNT(DISTINCT B.bidder_id) AS unique_bidders
FROM Categories C
LEFT JOIN Items I ON C.category_id = I.category_id
LEFT JOIN Auctions A ON I.item_id = A.item_id
LEFT JOIN Bids B ON A.auction_id = B.auction_id
GROUP BY C.category_id, C.category_name
ORDER BY total_sales DESC;

-- Query 5: Find auctions ending soon with high activity
SELECT 
    A.auction_id,
    I.item_name,
    A.current_highest_bid,
    A.reserve_price,
    CASE 
        WHEN A.current_highest_bid >= A.reserve_price THEN 'Reserve Met'
        ELSE 'Reserve Not Met'
    END AS reserve_status,
    COUNT(B.bid_id) AS bid_count,
    A.end_time,
    TIMESTAMPDIFF(HOUR, NOW(), A.end_time) AS hours_remaining
FROM Auctions A
JOIN Items I ON A.item_id = I.item_id
LEFT JOIN Bids B ON A.auction_id = B.auction_id
WHERE A.status = 'Open' 
    AND A.end_time BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 48 HOUR)
GROUP BY A.auction_id, I.item_name, A.current_highest_bid, A.reserve_price, A.end_time
HAVING bid_count > 2
ORDER BY hours_remaining ASC;

-- Query 6: User engagement analysis (complex subquery)
SELECT 
    engagement_data.*,
    CASE 
        WHEN engagement_score >= 8 THEN 'Highly Active'
        WHEN engagement_score >= 5 THEN 'Moderately Active'
        WHEN engagement_score >= 2 THEN 'Low Activity'
        ELSE 'Inactive'
    END AS engagement_level
FROM (
    SELECT 
        U.user_id,
        U.username,
        COUNT(DISTINCT B.auction_id) AS auctions_bid_on,
        COUNT(DISTINCT I.item_id) AS items_listed,
        COUNT(DISTINCT T1.transaction_id) AS purchases,
        COUNT(DISTINCT T2.transaction_id) AS sales,
        (COUNT(DISTINCT B.auction_id) + 
         COUNT(DISTINCT I.item_id) * 2 + 
         COUNT(DISTINCT T1.transaction_id) * 3 + 
         COUNT(DISTINCT T2.transaction_id) * 3) AS engagement_score
    FROM Users U
    LEFT JOIN Bids B ON U.user_id = B.bidder_id
    LEFT JOIN Items I ON U.user_id = I.seller_id
    LEFT JOIN Transactions T1 ON U.user_id = T1.buyer_id
    LEFT JOIN Transactions T2 ON U.user_id = T2.seller_id
    GROUP BY U.user_id, U.username
) AS engagement_data
ORDER BY engagement_score DESC;

-- ============================================================================
-- SECTION 7: EXAMPLE USAGE & TESTING
-- ============================================================================

-- Test 1: View active auctions
SELECT * FROM ActiveAuctionsView;

-- Test 2: Place a bid using the stored procedure
CALL PlaceBid(1, 3, 350.00);

-- Test 3: Get user statistics
CALL GetUserStats(2);

-- Test 4: View completed transactions
SELECT * FROM CompletedTransactionsView;

-- Test 5: Close an auction
-- CALL CloseAuction(1);

-- Test 6: Check audit log
SELECT * FROM AuditLog ORDER BY change_timestamp DESC LIMIT 10;

-- ============================================================================
-- SECTION 8: PERFORMANCE ANALYSIS QUERIES
-- ============================================================================

-- Show indexes on key tables
SHOW INDEX FROM Bids;
SHOW INDEX FROM Auctions;

-- Explain query performance for bid tracking
EXPLAIN SELECT 
    A.auction_id,
    I.item_name,
    COUNT(B.bid_id) AS total_bids,
    MAX(B.bid_amount) AS highest_bid
FROM Auctions A
JOIN Items I ON A.item_id = I.item_id
LEFT JOIN Bids B ON A.auction_id = B.auction_id
WHERE A.status = 'Open'
GROUP BY A.auction_id, I.item_name;
