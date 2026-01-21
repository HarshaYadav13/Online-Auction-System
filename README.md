# Online Auction Platform - DBMS Project

## Overview
This project is a pure Database Management System (DBMS) implementation of an online auction platform. It focuses on back-end logic, data integrity, and relational modeling without a front-end interface.

## Key Features
- **Normalized Schema:** 3NF design covering Users, Items, Auctions, and Bids.
- **ACID Compliance:** Uses SQL Transactions to handle race conditions during bidding.
- **Data Integrity:** Implements Foreign Keys and Triggers to prevent bids on closed auctions.
- **Complex Queries:** Utilizes Joins and Aggregate functions to determine auction winners.

## How to Run
1. Open MySQL Workbench.
2. Run the `Online_Auction_Platform_DBMS.sql` script.
3. Observe the output to see transaction handling and trigger validation in action.
