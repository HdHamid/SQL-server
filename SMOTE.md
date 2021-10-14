# SMOTE WITH T-SQL
Smote algorithm is based on KNN, and here I'm going to show you how to implement it using T-SQL.


## At first, I'm supposed to create sample data, so here is my code.
```bash
drop table if exists ###Vectores
create table ##Vectores 
(
ID int identity(1,1),
F1 DECIMAL(5,2),
F2 DECIMAL(5,2),
Label CHAR
)

TRUNCATE TABLE ##Vectores
GO 


DECLARE @Range INT = 10
DECLARE @INTERVAL INT = 0

INSERT INTO  ##Vectores 
(F1,F2,Label)
SELECT  ((ABS(CHECKSUM(NEWID()))%@Range)+RAND())+@INTERVAL
,((ABS(CHECKSUM(NEWID()))%@Range)+RAND())+@INTERVAL,'A'
GO 300

DECLARE @Range INT = 0
DECLARE @RangeNew INT = 5
DECLARE @INTERVAL INT = 10

INSERT INTO  ##Vectores 
(F1,F2,Label)
SELECT  @Range+((ABS(CHECKSUM(NEWID()))%@RangeNew)+RAND())+@INTERVAL
,@Range+((ABS(CHECKSUM(NEWID()))%@RangeNew)+RAND())+(@INTERVAL/2),'B'
GO 20

DECLARE @Range INT = 0
DECLARE @RangeNew INT = 5
DECLARE @INTERVAL INT = 10

INSERT INTO  ##Vectores 
(F1,F2,Label)
SELECT  @Range+((ABS(CHECKSUM(NEWID()))%@RangeNew)+RAND())+@INTERVAL
,@Range+((ABS(CHECKSUM(NEWID()))%@RangeNew)+RAND()),'C'
GO 30

```

As a result of the previous step, you can see this picture from Power BI 

![Image of Yaktocat](https://github.com/HdHamid/SQL-server/blob/T-Sql-Scripts/Smote1.jpg)

As you see, there are three classes here and one of them has the most records and it can make Bias a side effect.
Therefore I'm going to implement Smote to generate some records for the other two classes. You can see the T-SQL code in the following.

First, we find two classes with less data:
```bash 

DROP TABLE IF EXISTS #IMBALANCE
;WITH STP1 AS 
	(
	SELECT COUNT(1) Cnt,Label FROM ##Vectores
	GROUP BY Label
	)
,STP2 AS 
	(SELECT *,MAX(Cnt) OVER() AS [Max] FROM STP1)
,STP3 AS 
	(SELECT *,([MAX]-Cnt) as Iterate,(([MAX]-Cnt)*1.00/[MAX])*100 AS Pcnt FROM STP2)
SELECT * INTO #IMBALANCE FROM STP3 WHERE Pcnt >= 50

SELECT * FROM #IMBALANCE

```

Here I tried to make data for two classes randomly that had less data by using their initial data
```bash
DECLARE @k INT = 8,@Offset int = 2

DROP TABLE IF EXISTS #STP2
;WITH STP1 AS 
(SELECT  ROW_NUMBER() OVER(PARTITION BY I.Label ORDER BY NEWID()) RandomTop,V.*,I.Iterate FROM ##Vectores V 
INNER JOIN #IMBALANCE I on I.Label = v.Label
CROSS JOIN SYS.objects S)
SELECT * INTO #STP2 from  STP1 WHERE RandomTop <= Iterate
```

Now, I'm going to scale data 
```bash
DROP TABLE IF EXISTS #GETRAND_NN
;WITH Scaling AS 
			(
			 SELECT S2.RandomTop,s2.ID as [sID],v.ID as vID,S2.F1 as sF1,s2.f2 as sF2,v.f1 as vF1,v.f2 as vF2
			 ,MAX(V.F1)OVER(PARTITION BY s2.Label) MaxF1,MAX(V.F2)OVER(PARTITION BY s2.Label) MaxF2,MIN(V.F1)OVER(PARTITION BY s2.Label) MinF1,MIN(V.F2)OVER(PARTITION BY s2.Label)MinF2
			 ,s2.Label
			 FROM #STP2 S2 
			 INNER JOIN ##Vectores V ON V.Label = S2.Label AND S2.ID <> V.ID
			 ) 				

,Scaling2 as 
			(
			 SELECT RandomTop,[sID],vID,sF1 AS sF1org,sF2 AS sF2org,vF1 AS vF1org,vF2 AS vF2org
			 ,(sF1-MinF1)/(MaxF1-MinF1) as sF1,(vF1-MinF1)/(MaxF1-MinF1) as vF1,
			 (sF2-MinF2)/(MaxF2-MinF2) as sF2,(vF2-MinF2)/(MaxF2-MinF2) as vF2
			 ,Label
			 FROM Scaling
			 )
``` 

Here I calculated the distance of observations by using Euclidean distance.
```bash 
/*KNN*/
,Distance AS 
		(
		SELECT *,SQRT(SQUARE(sF1-vF1)+SQUARE(sF2-vF2)) AS Distance FROM Scaling2
		)


,CALC_KNN AS --Further LIKE Kmean++ P()
(SELECT *,ROW_NUMBER() OVER(PARTITION BY label,RandomTop ORDER BY Distance Desc) AS KNN FROM Distance)

,SELECT_KNN AS (SELECT * FROM CALC_KNN WHERE KNN between @Offset and @Offset + @k)

,GETRAND_NN AS 
(SELECT *,ROW_NUMBER() OVER(PARTITION BY label,RandomTop ORDER BY NEWID()) AS RANDKNN FROM SELECT_KNN)
SELECT * INTO #GETRAND_NN FROM GETRAND_NN WHERE RANDKNN = 1
```

And for the last step I calculate some random points based on each class observations (between them)
```bash
;WITH SAMPLES_Fin as
(SELECT *
,sF1org+(RAND()*(vF1org-sF1org)) AS SampleF1
,sF2org+(RAND()*(vF2org-sF2org)) AS SampleF2
FROM #GETRAND_NN)

INSERT INTO ##Vectores(F1,F2,Label)
SELECT SampleF1,SampleF2,Label FROM SAMPLES_Fin

```
And you can see the result in this picture 
![Image of Yaktocat](https://github.com/HdHamid/SQL-server/blob/T-Sql-Scripts/Smote2.jpg)
