-- This script adjusts the Experience column for users where a tagging error has occured and they are shown as New having already completed a transaction

CREATE OR REPLACE TABLE WISE_TASK_BUILD AS (
WITH 
--Find players who are New and also have completed a successful transfer
EXPERIENCE_DATE_FIX AS (
SELECT DISTINCT 
A.USER_ID,
MIN(UPDATED_DT) AS DATE_FIX_DT,-- Find the date of their first successful transfer
FROM 
wise_funnel_events_regional A
INNER JOIN (SELECT DISTINCT USER_ID FROM wise_funnel_events_regional WHERE EXPERIENCE = 'New') B
ON A.USER_ID=B.USER_ID
WHERE EVENT_NAME = 'Transfer Transferred'
GROUP BY 1
)  

, BUILD AS (
SELECT 
RD.EVENT_NAME,
CASE
	WHEN RD.EVENT_NAME = 'Transfer Created'THEN 1 
	WHEN RD.EVENT_NAME = 'Transfer Funded' THEN 2 
	WHEN RD.EVENT_NAME = 'Transfer Transferred' THEN 3 
END AS EVENT_ORDER,
RD.DT,
RD.UPDATED_DT,
RD.EXPERIENCE,
DF.DATE_FIX_DT,
RD.USER_ID,
RD.REGION,
RD.PLATFORM,
RD.TRANSFER_ID,
CASE 
WHEN RD.EXPERIENCE = 'Existing' AND RD.DT<=DF.DATE_FIX_DT THEN 'New' --If Experience='Existing' but the user has New appearing at a later date
WHEN RD.EXPERIENCE = 'New' AND RD.DT>DF.DATE_FIX_DT THEN 'Existing' --If Experience='New' but the user has 'Existing' appearing at a later date
ELSE RD.EXPERIENCE
end AS EXPERIENCE_FIX, --Updated Experience Column

FROM wise_funnel_events_regional RD
LEFT JOIN EXPERIENCE_DATE_FIX DF
ON DF.USER_ID=RD.USER_ID)

-- Create new base table for the scripts 
SELECT EVENT_NAME,DT,USER_ID,REGION,PLATFORM,EXPERIENCE_FIX AS EXPERIENCE, UPDATED_DT,TRANSFER_ID FROM BUILD
ORDER BY USER_ID, UPDATED_DT,EVENT_ORDER)
