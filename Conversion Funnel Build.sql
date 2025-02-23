--Main source table
WITH MAIN AS (SELECT *
FROM 
WISE_TASK_BUILD)
,

-- Separate sub queries for each stage of the funnel
TC AS (
SELECT 
event_name,
user_id,
updated_dt as dt,
transfer_id,
region,
platform,
experience
FROM MAIN 
where event_name = 'Transfer Created'
)

, TF AS (
SELECT 
event_name,
user_id,
updated_dt as dt,
transfer_id,
region,
platform,
experience
FROM MAIN 
where event_name = 'Transfer Funded'
)

 , TT AS (
SELECT 
event_name,
user_id,
updated_dt as dt,
transfer_id,
region,
platform,
experience
FROM MAIN 
where event_name = 'Transfer Transferred'
)

--Build structure of the table to get a row for each user,date, region,experience, platform
 
,PLAYER_FUNNEL_BUILD AS (

SELECT distinct
FB.dt
,FB.REGION
, FB.EXPERIENCE
, FB.PLATFORM
, TC.USER_ID
, TC.transfer_id AS TRANSFER_CR

FROM FUNNEL_BUILD FB
LEFT JOIN TC 
ON TC.DT=FB.DT
AND TC.REGION=FB.REGION
AND TC.EXPERIENCE=FB.EXPERIENCE
AND TC.PLATFORM=FB.PLATFORM)
 
-- Final output that shows the funnel of each transaction at a user and date level
, FINAL_BUILD AS (
SELECT 
PFB.dt
,PFB.REGION
, PFB.EXPERIENCE
, null as existing_flag
, PFB.PLATFORM
, PFB.USER_ID
, PFB.TRANSFER_CR
, TF.transfer_id AS TRANSFER_FU
, TT.transfer_id AS TRANSFER_TR
FROM PLAYER_FUNNEL_BUILD PFB

LEFT JOIN TF 
ON TF.transfer_id=PFB.TRANSFER_CR
AND TF.DT=PFB.DT

LEFT JOIN TT 
ON TT.transfer_id=PFB.TRANSFER_CR
AND TT.DT=PFB.DT

)

SELECT * FROM FINAL_BUILD
