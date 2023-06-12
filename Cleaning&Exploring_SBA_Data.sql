/****** Cleaning data  ******/

select *
into sba_naics_sector_codes_description 
from(

	select 
		  [NAICS_Industry_Description],
		  iif([NAICS_Industry_Description] like '%–%', substring([NAICS_Industry_Description], 8, 2 ), '') LookupCodes,
		  iif([NAICS_Industry_Description] like '%–%', ltrim(substring([NAICS_Industry_Description], CHARINDEX('–', [NAICS_Industry_Description]) + 1, LEN([NAICS_Industry_Description]) )), '') Sector
	  from [PortfolioProject].[dbo].[sba_industry_standards]
	  where [NAICS_Codes] = ''
) main
where 
	LookupCodes != ''


	SELECT TOP (1000) [NAICS_Industry_Description]
      ,[LookupCodes]
      ,[Sector]
  FROM [PortfolioProject].[dbo].[sba_naics_sector_codes_description]
  order by LookupCodes

insert into [dbo].[sba_naics_sector_codes_description]
values 
  ('Sector 31 – 33 – Manufacturing', 32, 'Manufacturing'), 
  ('Sector 31 – 33 – Manufacturing', 33, 'Manufacturing'), 
  ('Sector 44 - 45 – Retail Trade', 45, 'Retail Trade'),
  ('Sector 48 - 49 – Transportation and Warehousing', 49, 'Transportation and Warehousing')

update  [dbo].[sba_naics_sector_codes_description]
set Sector = 'Manufacturing'
where LookupCodes = 31


/****** Exploring data  ******/

--Q1---
---Summary of All PPP Approved Lending
--Note, there is also servicing Lender
SELECT
    COUNT(LoanNumber) AS Loans_Approved,
    SUM(InitialApprovalAmount) AS Total_Net_Dollars,
    AVG(InitialApprovalAmount) AS Average_Loan_Size,
    (SELECT COUNT(DISTINCT OriginatingLender) FROM [dbo].[sba_public_data]) AS Total_Originating_Lender_Count
FROM
    [PortfolioProject].[dbo].[sba_public_data]
ORDER BY
    Average_Loan_Size DESC;


---Summary of 2021 PPP Approved Lending
SELECT
    COUNT(LoanNumber) AS Loans_Approved,
    SUM(InitialApprovalAmount) AS Total_Net_Dollars,
    AVG(InitialApprovalAmount) AS Average_Loan_Size,
    (SELECT COUNT(DISTINCT OriginatingLender) FROM [dbo].[sba_public_data] WHERE YEAR(DateApproved) = 2021) AS Total_Originating_Lender_Count
FROM
    [PortfolioProject].[dbo].[sba_public_data]
WHERE
    YEAR(DateApproved) = 2021
ORDER BY
    Average_Loan_Size DESC;


---Summary of 2020 PPP Approved Lending
SELECT
    COUNT(LoanNumber) AS Loans_Approved,
    SUM(InitialApprovalAmount) AS Total_Net_Dollars,
    AVG(InitialApprovalAmount) AS Average_Loan_Size,
    (SELECT COUNT(DISTINCT OriginatingLender) FROM [dbo].[sba_public_data] WHERE YEAR(DateApproved) = 2020) AS Total_Originating_Lender_Count
FROM
    [PortfolioProject].[dbo].[sba_public_data]
WHERE
    YEAR(DateApproved) = 2020
ORDER BY
    Average_Loan_Size DESC;



---Q2---
---Summary of 2021 PPP Approved Loans per Originating Lender, loan count, total amount and average
--Top 15 Originating Lenders for 2021 PPP Loans
--Data is ordered by Net_Dollars
SELECT TOP 15
    OriginatingLender,
    COUNT(LoanNumber) AS Loans_Approved,
    SUM(InitialApprovalAmount) AS Net_Dollars,
    AVG(InitialApprovalAmount) AS Average_Loan_Size
FROM
    [PortfolioProject].[dbo].[sba_public_data]
WHERE
    YEAR(DateApproved) = 2021
GROUP BY
    OriginatingLender
ORDER BY
    Net_Dollars DESC;


SELECT TOP 15
    OriginatingLender,
    COUNT(LoanNumber) AS Loans_Approved,
    SUM(InitialApprovalAmount) AS Net_Dollars,
    AVG(InitialApprovalAmount) AS Average_Loan_Size
FROM
    [PortfolioProject].[dbo].[sba_public_data]
WHERE
    YEAR(DateApproved) = 2020
GROUP BY
    OriginatingLender
ORDER BY
    Net_Dollars DESC;



---3----
---Top 20 Industries that received the PPP Loans in 2021
-- I need to add the NAICS codes to the GitHub Repo, extracted from SQL
WITH cte AS (
	SELECT
		ncd.Sector,
		COUNT(LoanNumber) AS Loans_Approved,
		SUM(CurrentApprovalAmount) AS Net_Dollars
	FROM
		[PortfolioProject].[dbo].[sba_public_data] main
	INNER JOIN
		[dbo].[sba_naics_sector_codes_description] ncd ON LEFT(CAST(main.NAICSCode AS VARCHAR), 2) = ncd.LookupCode
	WHERE
		YEAR(DateApproved) = 2021
	GROUP BY
		ncd.Sector
	--order by 3 desc

)
SELECT
	Sector,
	Loans_Approved,
	SUM(Net_Dollars) OVER (PARTITION BY Sector) AS Net_Dollars,
	--SUM(Net_Dollars) OVER() AS Total,
	CAST(1. * Net_Dollars / SUM(Net_Dollars) OVER() AS DECIMAL(5,2)) * 100 AS "Percent by Amount"  
FROM cte  
order by 3 desc
--where year(DateApproved) = 2021 

---Q4---
--States and Territories
SELECT
    BorrowerState AS state,
    COUNT(LoanNumber) AS Loan_Count,
    SUM(CurrentApprovalAmount) AS Net_Dollars
--where cast(DateApproved as date) < '2021-06-01'
FROM
    [PortfolioProject].[dbo].[sba_public_data] main
GROUP BY
    BorrowerState
ORDER BY
    state;


---Q5----
---Demographics for PPP
----Loan counts and net dollars by race----
SELECT
    race,
    COUNT(LoanNumber) AS Loan_Count,
    SUM(CurrentApprovalAmount) AS Net_Dollars
FROM
    [PortfolioProject].[dbo].[sba_public_data]
GROUP BY
    race
ORDER BY
    Net_Dollars;

----Loan counts and net dollars by gender----
SELECT
    gender,
    COUNT(LoanNumber) AS Loan_Count,
    SUM(CurrentApprovalAmount) AS Net_Dollars
FROM
    [PortfolioProject].[dbo].[sba_public_data]
GROUP BY
    gender
ORDER BY
    Net_Dollars;

----Loan counts and net dollars by ethnicity----
SELECT
    Ethnicity,
    COUNT(LoanNumber) AS Loan_Count,
    SUM(CurrentApprovalAmount) AS Net_Dollars
FROM
    [PortfolioProject].[dbo].[sba_public_data]
GROUP BY
    Ethnicity
ORDER BY
    Net_Dollars;

----Loan counts and net dollars by veteran status----
SELECT
    Veteran,
    COUNT(LoanNumber) AS Loan_Count,
    SUM(CurrentApprovalAmount) AS Net_Dollars
FROM
    [PortfolioProject].[dbo].[sba_public_data]
GROUP BY
    Veteran
ORDER BY
    Net_Dollars;

---Q6---
---How much of the PPP Loans of 2021 have been fully forgiven
SELECT
    COUNT(LoanNumber) AS Count_of_Payments,
    SUM(ForgivenessAmount) AS Forgiveness_amount_paid
FROM
    [PortfolioProject].[dbo].[sba_public_data]
WHERE
    YEAR(DateApproved) = 2020
    AND ForgivenessAmount <> 0;


---Summary of 2021 PPP Approved Lending
SELECT
    COUNT(LoanNumber) AS Loans_Approved,
    SUM(InitialApprovalAmount) AS Total_Net_Dollars,
    SUM(ForgivenessAmount) AS Forgiveness_amount_paid,
    (SELECT COUNT(DISTINCT OriginatingLender) FROM [dbo].[sba_public_data] WHERE YEAR(DateApproved) = 2021) AS Total_Originating_Lender_Count
FROM
     [PortfolioProject].[dbo].[sba_public_data]
WHERE
    YEAR(DateApproved) = 2020
ORDER BY
    3 DESC;



--Q7---
--In which month was the highest amount given out by the SBA to borrowers
SELECT
    YEAR(DateApproved) AS Year_Approved,
    MONTH(DateApproved) AS Month_Approved,
    ProcessingMethod,
    SUM(CurrentApprovalAmount) AS Net_Dollars
FROM
    [PortfolioProject].[dbo].[sba_public_data]
GROUP BY
    YEAR(DateApproved),
    MONTH(DateApproved),
    ProcessingMethod
ORDER BY
    Net_Dollars DESC;
