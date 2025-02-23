--Add order of transactions to main table
WITH MAIN AS (SELECT *, DENSE_RANK() OVER(PARTITION BY USER_ID ORDER BY UPDATED_DT) AS TRANSACTION_ORDER
FROM 
WISE_TASK_BUILD)

, TT AS (
SELECT 
event_name,
user_id,
updated_dt as dt,
transfer_id,
region,
platform,
experience,
CASE WHEN EXPERIENCE = 'New' then 0
 WHEN EXPERIENCE = 'Existing' THEN 1
ELSE 1 END as existing_flag,
DENSE_RANK() OVER(PARTITION BY USER_ID ORDER BY UPDATED_DT) AS SUCCESSFUL_TRANSACTION_ORDER --Define if this is the users first successful transaction on this journey
FROM MAIN 
where event_name = 'Transfer Transferred'
)

,
--All created transactions
TC AS (
SELECT 
event_name,
user_id,
updated_dt as dt,
transfer_id,
region,
platform,
experience,
TRANSACTION_ORDER
FROM MAIN 
where event_name = 'Transfer Created'
)
--Final output that shows transfer attempts and successful transfers after a user has completed a successful transfer
, FINAL_BUILD AS (
SELECT
TT.USER_ID
, TT.EXPERIENCE
, MIN(TT.DT) AS FTT_DATE
, COUNT(DISTINCT TC.TRANSFER_ID) AS POST_FTT_ATT_COUNT
, COUNT(DISTINCT TT1.TRANSFER_ID) AS POST_FTT_SUCC_COUNT
FROM TT
LEFT JOIN TC 
ON TC.USER_ID=TT.USER_ID
AND TC.TRANSACTION_ORDER>1
LEFT JOIN (SELECT * FROM TT WHERE SUCCESSFUL_TRANSACTION_ORDER> 1) TT1
ON TT1.USER_ID=TT.USER_ID

WHERE TT.SUCCESSFUL_TRANSACTION_ORDER =1 

GROUP BY 1,2
)

SELECT * FROM FINAL_BUILD

