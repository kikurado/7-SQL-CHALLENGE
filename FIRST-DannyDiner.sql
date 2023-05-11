/* Case study Danny's Diner */
-- Author: Mohamed Elmasry
-- T-SQL was used to carry out that project


-- Schema structure

CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


-- Case Study Queries!

--1- What is the total amount each customer spent at the restaurant?

SELECT customer_id, SUM(PRICE) [Total Amount spent / customer ]
FROM menu M
INNER JOIN sales S
	ON M.product_id = S.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id,COUNT(DISTINCT(order_date)) [Count Visit/customer]
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

SELECT customer_id, TEMP.product_id, First_item, M.product_name
FROM 
(SELECT S.*,DENSE_RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE ) AS First_item
FROM menu M
INNER JOIN sales S
	ON M.product_id = S.product_id ) TEMP
INNER JOIN menu M
ON TEMP.product_id = M.product_id
WHERE First_item = 1
GROUP BY customer_id,TEMP.product_id, First_item, M.product_name;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?


SELECT TOP 1 M.product_name, COUNT(S.PRODUCT_ID) AS [Purchased times]
FROM sales S
INNER JOIN menu M
	ON S.product_id = M.product_id
GROUP BY M.product_name
ORDER BY 2 DESC
;

-- 5. Which item was the most popular for each customer?
WITH CTE AS (
SELECT customer_id,PRODUCT_NAME,COUNT(S.PRODUCT_ID) ORDER_COUNT, DENSE_RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY COUNT(S.PRODUCT_ID) DESC) RANK
FROM menu M
INNER JOIN sales S 
	ON M.product_id = S.product_id

GROUP BY customer_id,product_name
)
SELECT CUSTOMER_ID, PRODUCT_NAME
FROM CTE
WHERE RANK = 1;

--6. Which item was purchased first by the customer after they became a member?

WITH CTE1 AS (SELECT U.product_name,ORDER_DATE, JOIN_DATE,S.customer_id, 
			DENSE_RANK() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY ORDER_DATE ) RANK
FROM members M
INNER JOIN sales S 
	ON M.customer_id = S.customer_id
INNER JOIN menu U
	ON S.product_id = U.product_id
WHERE order_date >= join_date
)
SELECT customer_id, product_name,join_date [join date ], order_date AS [date first order after join ]
FROM CTE1
WHERE RANK  =1;



--7. Which item was purchased just before the customer became a member?

WITH CTE2 AS ( SELECT PRODUCT_NAME,S.customer_id, order_date,join_date,S.product_id,
			DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY ORDER_DATE DESC) RANK
FROM sales S
INNER JOIN members M
	ON S.customer_id = M.customer_id
INNER JOIN menu U
	ON S.product_id=U.product_id
WHERE order_date < join_date)
SELECT customer_id, product_name, join_date, order_date [last order before join date ]
FROM CTE2
WHERE RANK = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(DISTINCT(PRODUCT_NAME))[total items], SUM(PRICE)[total amount spent]
FROM members M
INNER JOIN sales S
	ON M.customer_id = S.customer_id
INNER JOIN menu U
	ON S.product_id = U.product_id
WHERE S.order_date < M.join_date
GROUP BY S.customer_id;




--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?

WITH POINT AS (SELECT customer_id,PRICE,PRODUCT_NAME,
	CASE WHEN product_name = 'SUSHI' THEN price * 20
	ELSE price * 10
	END AS points
FROM menu U
INNER JOIN sales S 
	ON U.product_id=S.product_id)

SELECT customer_id,	SUM(POINTS) [total points]
from POINT
GROUP BY customer_id;


/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
not just sushi — how many points do customer A and B have at the end of January? */ 

CREATE VIEW RESULTS
AS 
WITH CTE AS (SELECT S.customer_id,U.price,U.product_name ,M.join_date,DATEADD(DAY,6,JOIN_DATE) AS [ valid till ],S.order_date
FROM members M
INNER JOIN sales S
	ON M.customer_id = S.customer_id
INNER JOIN menu U
	ON U.product_id=S.product_id

WHERE S.order_date < '2021-01-31' 
)
SELECT CUSTOMER_ID, 
	CASE WHEN product_name = 'SUSHI' THEN price * 20
		WHEN order_date < [ valid till ] AND ORDER_DATE >= JOIN_DATE THEN price * 20
		ELSE price * 10
		END AS TOTAL_POINTS
FROM CTE


SELECT CUSTOMER_ID, SUM(TOTAL_POINTS) AS TOTAL

FROM RESULTS
GROUP BY customer_id
