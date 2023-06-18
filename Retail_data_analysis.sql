

--CREATE DATABASE db_RETAIL_DATA_ANALYSIS;

--USE db_RETAIL_DATA_ANALYSIS;


--SQL RETAIL DATA ANALYSIS Case Study

-----------------------------------------------------DATA PREPRATION AND UNDERSTANDING----------------------------------------------------------

--Q1--BEGIN 


--	WHAT IS THE TOTAL NUMBER OF ROWS IN EACH OF THE THREE TABLES IN THE DATABASE?


SELECT 'Customer' AS TABLE_NAME, COUNT(*) AS NO_OF_ROWS FROM Customer
UNION ALL
SELECT 'prod_cat_info', COUNT(*) FROM prod_cat_info
UNION ALL
SELECT 'TRANSACTIONS', COUNT(*) FROM Transactions;


--Q1--END


--Q2--BEGIN 


--	WHAT IS THE TOTAL NUMBER OF TRANSACTIONS THAT HAVE A RETURN?


WITH CTE AS 
			(
			SELECT 
			T.transaction_id AS TRANSACTION_ID, ROW_NUMBER() OVER(PARTITION BY T.transaction_id ORDER BY T.transaction_id) AS RANK_ 
			FROM Transactions AS T
			)
SELECT 
COUNT(TRANSACTION_ID) AS TRANSACTIONS_RETURNED 
FROM CTE
WHERE RANK_ = 2;


--Q2--END


--Q3--BEGIN 


--	AS YOU WOULD HAVE NOTICED, THE DATES PROVIDED ACROSS THE DATASETS ARE NOT IN A CORRECT FORMAT. AS FIRST STEPS, 
--	PLEASE CONVERT THE DATE VERIABLES INTO VALID DATE BEFORE PROCEEDING AHEAD.


SELECT CONVERT(DATE,T.TRAN_DATE, 105) AS TRAN_DATE FROM Transactions AS T;
SELECT CONVERT(DATE,C.DOB, 105) AS DOB FROM Customer AS C;


--Q3--END


--Q4--BEGIN 


--	WHAT IS THE TIME RANGE OF THE TRANSACTION DATA AVAILABLE FOR ANALYSIS ?
--	SHOW THE OUTPUT IN NUMBER OF DAYS, MONTHS AND YEARS SIMULTANEOUSLY IN DIFFERENT COLUMNS.


SELECT 
DATEDIFF(DAY, MIN(T.tran_date), MAX(T.tran_date)) AS TRANSACTON_RANGE_DAYS, 
DATEDIFF(MONTH, MIN(T.tran_date), MAX(T.tran_date)) AS TRANSACTON_RANGE_MONTHS, 
DATEDIFF(YEAR, MIN(T.tran_date), MAX(T.tran_date)) AS TRANSACTON_RANGE_YEARS
FROM Transactions AS T;


--Q4--END


--Q5--BEGIN 


--	WHICH PRODUCT CATEGORY DOES THE SUB-CATEGORY "DIY" BELONG TO?


SELECT P.prod_cat FROM prod_cat_info AS P 
WHERE P.prod_subcat = 'DIY'




--Q5--END




-----------------------------------------------------DATA ANALYSIS----------------------------------------------------------





--Q1--BEGIN 


--	WHICH CHANNEL IS MOST FREQUENTLY USED FOR TRANSACTIONS?

WITH CTE(STORE_TYPE, NUM_OF_TRANS, RANK_) AS
											(
											SELECT T.Store_type, COUNT(T.Store_type), RANK() OVER(ORDER BY COUNT(T.Store_type) DESC) FROM Transactions AS T
											GROUP BY T.Store_type
											)
SELECT STORE_TYPE, NUM_OF_TRANS FROM CTE 
WHERE RANK_ = 1;

--Q1--END


--Q2--BEGIN 


--	WHAT IS THE COUNT OF THE MALE AND FEMALE CUSTOMERS IN THE DATABASE?


SELECT C.Gender, 
SUM(CASE 
WHEN C.Gender IS NULL THEN 1 ELSE 1
END) AS CNT_OF_GENDER
FROM Customer AS C
GROUP BY C.Gender;

--Q2--END


--Q3--BEGIN 


--	FROM WHICH CITY DO WE HAVE MAXIMUM NUMBER OF CUSTOMERS AND HOW MANY 

WITH CTE(CITY, NUM_OF_CUST, RANK_) AS
			(
			SELECT C.city_code,
			SUM(CASE WHEN C.city_code IS NULL THEN 1 ELSE 1 END),
			RANK() OVER (ORDER BY SUM(CASE WHEN C.city_code IS NULL THEN 1 ELSE 1 END) DESC)
			FROM Customer AS C
			GROUP BY C.city_code
			)
SELECT CITY, NUM_OF_CUST FROM CTE
WHERE RANK_ = 1;


--Q3--END


--Q4--BEGIN 


--	HOW MANY SUB-CATEGORIES ARE THERE UNDER THE BOOK CATEGORY?


SELECT P.prod_cat, COUNT(P.prod_subcat) AS NO_OF_SUBCAT FROM prod_cat_info AS P
WHERE P.prod_cat = 'BOOKS'
GROUP BY P.prod_cat;


--Q4--END


--Q5--BEGIN 


--	WHAT IS THE MAXIMUM QUANTITY OF PRODUCTS EVER ORDERD?


SELECT 
MAX(CONVERT(INT,T.Qty)) AS MAXIMUM_QUANTITY_OF_PRODUCTS_EVER_ORDERD 
FROM Transactions AS T;



--Q5--END


--Q6--BEGIN 


--	WHAT IS NET TOTAL REVANUE GENRATED IN CATEGORIES ELECTRONIC AND BOOKS?

SELECT ROUND(SUM(T.total_amt),0) AS NET_REVANUE FROM Transactions AS T
LEFT JOIN prod_cat_info AS P
ON P.prod_sub_cat_code = T.prod_subcat_code AND P.prod_cat_code = T.prod_cat_code
WHERE P.prod_cat IN ('ELECTRONICS','BOOKS');


--Q6--END


--Q7--BEGIN 


--	HOW MANY CUSTOMERS HAVE >10 TRANSACTIONS WITH US, EXCLUDING RETURNS?

WITH CTE AS
			(
			SELECT T.cust_id AS CUST, COUNT(T.cust_id) AS CNT FROM Transactions AS T
			WHERE T.Qty >0
			GROUP BY T.cust_id
			HAVING COUNT(T.cust_id) > 10
			)
SELECT COUNT(*) AS COUNT_OF_CUST_HAVING_MORE_THEN_10_TRANS_WITH_US_EXC_RETURNS FROM CTE;


--Q7--END


--Q8--BEGIN 


--	WHAT IS THE COMBINED REVANUE EARNED FROM "ELECTRONICS" AND "CLOTHING" CATEGORIES, FROM "FLAGSHIP STORES"?


SELECT ROUND(SUM(T.total_amt),0) AS TOTAL_REVANUE FROM Transactions AS T
INNER JOIN prod_cat_info AS P
ON P.prod_cat_code = T.prod_cat_code AND P.prod_sub_cat_code = T.prod_subcat_code
WHERE P.prod_cat IN ('ELECTRONICS', 'CLOTHING') AND T.Store_type LIKE '%FLAGSH%';



--Q8--END


--Q9--BEGIN 


--	WHAT IS THE TOTAL REVANUE GENERATED FROM "MALE" CUSTOMERS IN "ELECTRONICS" CATEGORY? OUTPUT SHOULD DISPLAY TOTAL REVANUE BY PRODUCT SUB-CAT. 


SELECT 
P.prod_subcat AS PRODUCT_SUB_CATEGORY, SUM(T.total_amt) AS REVANUE 
FROM Transactions AS T
INNER JOIN Customer AS C
ON C.customer_Id = T.cust_id
INNER JOIN prod_cat_info AS P
ON P.prod_cat_code = T.prod_cat_code AND P.prod_sub_cat_code = T.prod_subcat_code
WHERE C.Gender = 'M' AND P.prod_cat = 'ELECTRONICS'
GROUP BY P.prod_subcat;


--Q9--END


--Q10--BEGIN 


--	WHAT IS PERCENTAGE OF SALES AND RETURNS BY PRODUCT SUB-CAT ? DISPLAY ONLY TOP 5 SUB-CAT IN TERMS OF SALES.

SELECT TOP 5
P.prod_subcat, 
ROUND(SUM(T.total_amt)*100.0/(SELECT SUM(T.total_amt) FROM Transactions AS T),2) AS PERCENT_OF_SALES_OF_REVANUE,
ROUND(SUM(CASE WHEN T.total_amt<0 THEN T.total_amt ELSE 0 END)*(-100.0)/(SELECT SUM(T.total_amt) FROM Transactions AS T WHERE QTY>0),2) AS PERCENT_OF_RETURN_OF_REVANUE
FROM Transactions AS T
LEFT JOIN prod_cat_info AS P
ON P.prod_cat_code= T.prod_cat_code AND P.prod_sub_cat_code = T.prod_subcat_code
GROUP BY T.prod_cat_code, P.prod_subcat
ORDER BY SUM(T.total_amt) DESC;


--Q10--END


--Q11--BEGIN 


--	FOR ALL CUSTOMERS AGED BETWEEN 25 TO 35 YERS FIND WHAT IS TOTAL NET REVANUE GENERATED BY THESE 
--	CONSUMERS IN LAST 30 DAYS OF TRANSACTIONS FROM MAX TRANSACTION DATA AVAILABLE IN THE DATA?



SELECT ROUND(SUM(T.total_amt),0) AS NET_REVANUE FROM Transactions AS T
INNER JOIN Customer AS C
ON C.customer_Id = T.cust_id
WHERE T.tran_date IN

--	MY GUESS IS THAT AGE WHILE DOING THE TRANSACTION IS BETWEEN 25 AND 35 

					( SELECT T.tran_date FROM Transactions AS T
					WHERE 
					DATEDIFF(DAY, CONVERT(DATE,T.tran_date), CONVERT(DATE, (SELECT MAX(T.tran_date) FROM Transactions AS T))) <= 30)
					AND 
					(DATEPART(YEAR,T.tran_date)-DATEPART(YEAR,C.DOB) + (CASE WHEN DATEPART(MONTH,T.tran_date)-DATEPART(YEAR,C.DOB)>0 THEN -1 ELSE 0 END)) BETWEEN 25 AND 35;



--Q11--END


--Q12--BEGIN 


--	WHICH PRODUCT CATEGORY HAS SEEN THE MAX VALUE OF RETURNS IN THE LAST 3 MONTHS OF TRANSACTIONS?


SELECT TOP 1 
P.prod_cat, ROUND(SUM(T.total_amt),0) AS VALUE_,RANK() OVER(ORDER BY SUM(T.total_amt)) AS RANK_
FROM Transactions AS T
LEFT JOIN prod_cat_info AS P
ON P.prod_cat_code = T.prod_cat_code AND P.prod_sub_cat_code = T.prod_subcat_code
WHERE T.Qty<0 AND DATEDIFF(MONTH, T.tran_date, (SELECT MAX(T.tran_date) FROM Transactions AS T)) <= 3
GROUP BY P.prod_cat;


--Q12--END


--Q13--BEGIN 


--	WHICH STORE TYPE SELLS THE MAXIMUM PRODUCTS ; BY VALUE OF SALES AMOUNT AND BY QUANTITY SOLD?


SELECT T.Store_type,  ROUND(SUM(T.total_amt),0) MAX_VALUE, SUM(CONVERT(INT,T.Qty)) AS MAX_QTY FROM Transactions AS T
GROUP BY T.Store_type
HAVING  
SUM(T.total_amt) >= ALL(SELECT SUM(T.total_amt) FROM Transactions AS T GROUP BY T.Store_type)
AND
SUM(CONVERT(INT,T.Qty)) >= ALL(SELECT  SUM(CONVERT(INT,T.Qty)) FROM Transactions AS T GROUP BY T.Store_type);



--Q13--END


--Q14--BEGIN 


--	WHAT ARE THE CATEGORIES FOR WHICH AVERAGE REVANUE IS ABOVE THE OVERALL AVERAGE.


SELECT P.prod_cat, ROUND(AVG(T.total_amt),0) AS AVG_REVANUE FROM Transactions AS T
INNER JOIN prod_cat_info AS P
ON P.prod_cat_code = T.prod_cat_code AND P.prod_sub_cat_code = T.prod_subcat_code
GROUP BY P.prod_cat
HAVING AVG(T.total_amt) > (SELECT AVG(T.total_amt) FROM Transactions AS T);


--Q14--END


--Q15--BEGIN 


--FIND THE AVERAGE AND TOTAL REVANUE BY EACH SUB-CATEGORY FOR THE CATEGORIES WHICH ARE AMONG TOP 5 CATEGORIES IN TERMS OF QUANTITY SOLD.


SELECT 
P.prod_cat, P.prod_subcat, ROUND(AVG(T.total_amt),0) AS AVG_REVANUE, ROUND(SUM(T.total_amt),0) AS TOTAL_REVANUE 
FROM Transactions AS T
INNER JOIN prod_cat_info AS P
ON P.prod_cat_code = T.prod_cat_code AND T.prod_subcat_code = P.prod_sub_cat_code
WHERE T.prod_cat_code IN (SELECT TOP 5 T.prod_cat_code FROM Transactions AS T
GROUP BY T.prod_cat_code
ORDER BY SUM(CONVERT(INT, T.Qty)) DESC
)
GROUP BY P.prod_cat, P.prod_subcat
ORDER BY P.prod_cat, P.prod_subcat;


--Q15--END
























