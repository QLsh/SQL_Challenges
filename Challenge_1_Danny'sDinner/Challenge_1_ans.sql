
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- Q1 ANS
SELECT customer_id, SUM(price)
  FROM sales JOIN menu ON sales.product_id = menu.product_id
  GROUP BY customer_id;
  
-- 2. How many days has each customer visited the restaurant?
-- Q2 ANS
SELECT customer_id, COUNT(order_date)
  FROM sales
  GROUP BY customer_id;
  
-- 3. What was the first item from the menu purchased by each customer?
-- Q3 ANS
SELECT customer_id, product_name
  FROM sales JOIN menu ON sales.product_id = menu.product_id
  GROUP BY customer_id
  HAVING MIN(order_date);


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- Q4 ANS
SELECT product_name,COUNT(sales.product_id) AS "purchased_times"
  FROM sales JOIN menu ON sales.product_id = menu.product_id
  GROUP BY sales.product_id
  ORDER BY purchased_times DESC
  LIMIT 1;


-- 5. Which item was the most popular for each customer?
-- Q5 ANS
-- SELECT customer_id,product_name
--   FROM sales x JOIN menu ON sales.product_id = menu.product_id
--   WHERE COUNT(sales.product_id) >= ALL(SELECT COUNT(sales.product_id)
-- 										 FROM sales y
-- 										 WHERE y.customer_id=x.customer_id
-- 										   AND COUNT(y.product_id)>0);
WITH cte_most_popular AS (
	SELECT s.customer_id AS c_id,
		m.product_name AS p_name,
		RANK() OVER (
			PARTITION BY customer_id
			ORDER BY COUNT(m.product_id) DESC
		) AS rnk
	FROM sales AS s
		JOIN menu AS m ON s.product_id = m.product_id
	GROUP BY c_id,
		p_name
)
SELECT *
FROM cte_most_popular
WHERE rnk = 1;

-- 6. Which item was purchased first by the customer after they became a member?
-- Q6 ANS
SELECT sales.customer_id,product_name
  FROM sales 
  JOIN menu 
    ON sales.product_id = menu.product_id
  JOIN members
    ON sales.customer_id = members.customer_id
	WHERE order_date >= join_date
	GROUP BY sales.customer_id;
  

-- 7. Which item was purchased just before the customer became a member?
-- Q7 ANS
WITH last_purchase AS (
	SELECT sales.customer_id, 
		   product_name, 
		   RANK() OVER (
			PARTITION BY sales.customer_id
			ORDER BY order_date DESC
			) AS rnk
	  FROM sales 
	  JOIN menu 
		ON sales.product_id = menu.product_id
	  JOIN members
		ON sales.customer_id = members.customer_id
	  WHERE order_date < join_date
  )

SELECT customer_id, product_name
  FROM last_purchase
  WHERE rnk = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
-- Q8 ANS
WITH last_purchase AS (
	SELECT sales.customer_id, SUM(price) as total_spent,
		   product_name, COUNT(sales.product_id) as item
	  FROM sales 
	  JOIN menu 
		ON sales.product_id = menu.product_id
	  JOIN members
		ON sales.customer_id = members.customer_id
	  WHERE order_date < join_date
	  GROUP BY sales.customer_id
  )

SELECT customer_id, item, total_spent
  FROM last_purchase;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- Q9 ANS
WITH last_purchase AS (
	SELECT sales.customer_id, 
	CASE
	WHEN sales.product_id = 1 THEN menu.price*20
	ELSE menu.price*10
	END AS points
	  FROM sales 
	  JOIN menu 
		ON sales.product_id = menu.product_id
	  JOIN members
		ON sales.customer_id = members.customer_id
	  WHERE order_date >= join_date
  )
  
SELECT customer_id, SUM(points) as member_points
  FROM last_purchase
  GROUP BY customer_id;
  
  
  
  
  

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- Q10 ANS
WITH last_purchase AS (
	SELECT sales.customer_id, 
	CASE
	WHEN sales.product_id = 1 THEN menu.price*20
	WHEN ROUND(JULIANDAY(order_date) - JULIANDAY(join_date)) <= 6 THEN menu.price*20
	ELSE menu.price*10
	END AS points
	  FROM sales 
	  JOIN menu 
		ON sales.product_id = menu.product_id
	  JOIN members
		ON sales.customer_id = members.customer_id
	  WHERE order_date >= join_date
	    AND order_date <= '2021-01-31'
  )
  
SELECT customer_id, SUM(points) as member_points
  FROM last_purchase
  GROUP BY customer_id;
  
-- WITH cte_jan_member_points AS (
-- 	SELECT m.customer_id AS customer,
-- 		SUM(
-- 			CASE
-- 				WHEN s.order_date < m.join_date THEN 
-- 					CASE
-- 						WHEN m2.product_name = 'sushi' THEN (m2.price * 20)
-- 						ELSE (m2.price * 10)
-- 					END
-- 				WHEN s.order_date > (m.join_date + 6) THEN 
-- 					CASE
-- 						WHEN m2.product_name = 'sushi' THEN (m2.price * 20)
-- 						ELSE (m2.price * 10)
-- 					END
-- 				ELSE (m2.price * 20)
-- 			END
-- 		) AS member_points
-- 	FROM members AS m
-- 		JOIN sales AS s ON s.customer_id = m.customer_id
-- 		JOIN menu AS m2 ON s.product_id = m2.product_id
-- 	WHERE s.order_date <= '2021-01-31'
-- 	GROUP BY customer
-- )
-- SELECT *
-- FROM cte_jan_member_points
-- ORDER BY customer;


-- ---------------IN Q9 & Q10 the answer included the points for the purchase before the Join_Date which is different from how I understood the question.
