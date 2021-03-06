USE [XDatabase]
GO
/****** Object:  StoredProcedure [etl].[BuildProductMarketBasket]    Script Date: 4/21/2022 3:59:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [etl].[BuildProductMarketBasket]
as
IF OBJECT_ID('tempdb..#MainGrouping', 'U') IS NOT NULL
BEGIN
DROP TABLE #MainGrouping	
END	
CREATE TABLE #MainGrouping
(
	Vertical						VARCHAR(255)
,	MainGroupingID					VARCHAR(255) 
,	CountingGroup					VARCHAR(255)
--,	MainGroupingSubGrouping			VARCHAR(255)
,	Revenue							NUMERIC(18,9)
,	MainGroupingCount				INTEGER
,	MainGroupingSubGroupingCount	INTEGER
PRIMARY KEY( MainGroupingID, CountingGroup) 
)
INSERT INTO #MainGrouping
SELECT
	Vertical		
,	MainGroupingid					=	MainGrouping		
,	CountingGroup					=	CountingGroup
--,	MainGroupingSubGrouping			=	MainGroupingSubGrouping
,	Revenue							=	Revenue
,	MainGroupingCount				=	SUM(MainGroupingCount) OVER(PARTITION BY MainGrouping)
,	MainGroupingSubGroupingCount	=	NULL
FROM	(
		SELECT 
			Vertical				=	Vertical
		,	MainGrouping			=	i.ProductID
		,	CountingGroup			=	ISNULL(i.MasterCNUM,I.CustomerID)
		,	MainGroupingSubGrouping	=	TradeClassDesc		
		,	Revenue					=	SUM(InvoiceAmt) OVER(PARTITION BY i.ProductID) 
		,	MainGroupingCount		=	ROW_NUMBER() OVER (PARTITION BY I.ProductID, ISNULL(i.MasterCNUM,I.CustomerID) ORDER BY invoicedate) 
		FROM stage.Invoice I
		JOIN stage.Customer c
			ON	c.CustomerID = i.CustomerID
		WHERE	1=1
			AND YEAR(InvoiceDate) = 2019
			AND ExcludeReasonFlag = 0
			--and ProductID = 'JTS-1013'
			--AND i.MasterCNUM IS NOT NULL
		)A
WHERE	1=1
	AND	MainGroupingCount = 1
--*/

/*
UPDATE MG
SET
	MainGroupingSubGroupingCount	=	a.MainGroupingSubGroupingCount
FROM #MainGrouping MG
JOIN	(
		SELECT 
			MainGroupingID
		,	MainGroupingSubGroupingCount	=	COUNT(DISTINCT mg.MainGroupingSubGrouping)
		FROM #MainGrouping MG
		GROUP BY 
			MG.MainGroupingID
		) A
	ON	a.MainGroupingID = mg.MainGroupingID
select * from #MainGrouping--*/

SELECT
	Vertical
,	MainGroupingid
,	Revenue
,	MainGroupingCount		
,	SecondaryGrouping	
,	SecondaryRevenue					=	MAX(SecondaryRevenue					)
,	SecondaryGroupingCount				=	MAX(SecondaryGroupingCount				)
,	SecondaryGroupingSubGrouping		=	MAX(SecondaryGroupingSubGrouping		)
,	SecondaryGroupingSubGroupingCount	=	MAX(SecondaryGroupingSubGroupingCount	)
FROM	(
		SELECT
			Vertical
		,	MainGroupingid
		,	Revenue
		,	MainGroupingCount		
		,	SecondaryGrouping		
		,	SecondaryRevenue				
		,	SecondaryGroupingSubGrouping		=	CASE ROW_NUMBER() OVER (PARTITION BY Vertical, MainGroupingid, SecondaryGrouping ORDER BY SecondaryGroupingCount DESC) WHEN 1 THEN SecondaryGroupingSubGrouping END
		,	SecondaryGroupingSubGroupingCount	=	CASE ROW_NUMBER() OVER (PARTITION BY Vertical, MainGroupingid, SecondaryGrouping ORDER BY SecondaryGroupingCount DESC) WHEN 1 THEN SecondaryGroupingCount END
		,	SecondaryGroupingCount				=	SecondaryGroupingCount--SUM(SecondaryGroupingCount) OVER(PARTITION BY Vertical, MainGroupingid, SecondaryGrouping, SecondaryGroupingSubGrouping)
		FROM	(
				SELECT
					Vertical
				,	MainGroupingid
				,	Revenue
				,	MainGroupingCount		
				,	SecondaryGrouping		
				,	SecondaryRevenue				
				,	SecondaryGroupingSubGrouping		=	SecondaryGroupingSubGrouping--CASE ROW_NUMBER() OVER (PARTITION BY Vertical, MainGroupingid, SecondaryGrouping ORDER BY SecondaryGroupingCount DESC) WHEN 1 THEN SecondaryGroupingSubGrouping END
				--,	SecondaryGroupingSubGroupingCount	=	CASE ROW_NUMBER() OVER (PARTITION BY Vertical, MainGroupingid, SecondaryGrouping ORDER BY SecondaryGroupingCount DESC) WHEN 1 THEN SecondaryGroupingCount END
				,	SecondaryGroupingCount				=	SUM(SecondaryGroupingCount) OVER(PARTITION BY Vertical, MainGroupingid, SecondaryGrouping, SecondaryGroupingSubGrouping)
				FROM	(
						SELECT 
							Vertical
						,	MainGroupingid
						,	Revenue
						,	MainGroupingCount	
						,	SecondaryGroupingSubGrouping
						,	SecondaryGrouping		
						,	SecondaryRevenue				=	SUM(CASE WHEN SecondaryGroupingCount = 1 THEN SecondaryRevenue END)
						,	SecondaryGroupingCount			=	SUM(SecondaryGroupingCount)
						FROM (
							SELECT
								m.Vertical
							,	m.MainGroupingid
							,	Customer						=	ISNULL(i.MasterCNUM,I.CustomerID)
							,	Revenue
							,	MainGroupingCount				=	MainGroupingCount
							,	SecondaryGrouping				=	i.ProductID
							,	SecondaryGroupingSubGrouping	=	ISNULL(I2PTradeClassCst,'LEGACY - ' +TradeClassDesc)
							,	SecondaryRevenue				=	SUM(InvoiceAmt) OVER(PARTITION BY m.MainGroupingid, CountingGroup, i.ProductID) 
							,	SecondaryGroupingCount			=	CASE ROW_NUMBER() OVER (PARTITION BY m.MainGroupingid, I.ProductID, CountingGroup ORDER BY invoicedate) 	WHEN 1 THEN 1 ELSE 0 END
							FROM stage.Invoice I
							JOIN stage.Customer C
								ON	C.CustomerID = I.CustomerID
							JOIN --SELECT * FROM 
							#MainGrouping M
								ON	M.CountingGroup = ISNULL(i.MasterCNUM,I.CustomerID)
								AND	M.MainGroupingID <> I.ProductID
							WHERE	1=1
								AND YEAR(InvoiceDate) = 2019
								AND ExcludeReasonFlag = 0
								--and i.ProductID = 'mg-eve10p-cs'
								--AND MainGroupingid = 'LFI-BA-9079-05'
								--AND I.ProductID = 'LFI-BA-9731-03'
									--AND MainGroupingID= 'JTS-169'	
									--AND i.ProductID = 'JTS-418'
								) A
						WHERE	1=1
					GROUP BY 
							MainGroupingid
						,	Revenue
						,	MainGroupingCount		
						,	SecondaryGrouping		
						,	SecondaryRevenue	
						,	Vertical		
						,	SecondaryGroupingSubGrouping
						)A
				) A
		)A
WHERE	1=1					
							--AND MainGroupingID= 'JTS-169'
							--AND MainGroupingID= 'JTS-1047'	
							--and SecondaryGrouping = 'JTS-418'
GROUP BY
	Vertical
,	MainGroupingid	
,	Revenue
,	MainGroupingCount		
,	SecondaryGrouping	
HAVING MAX(SecondaryGroupingCount)>1
