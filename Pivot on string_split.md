# Get resources info by T-SQL

## CPU

If you want to seperate strings in multiple columns you can use this T-SQL code.

```bash

drop table if exists #tbl
;with stp1 as 
(
	select ID,ROW_NUMBER() over(partition by ID order by (select 0)) as ColName,value as Vl 
	from (values
			(1,'67,2021,6,25,23,2.417,0,2370.3,27.81,0,13.35')
			,(2,'85,2525,61,425,223,22.6,0,500.3,80.81,60,15.35,88,54')			
				) as Tbl1(ID,Col) cross apply string_split(Tbl1.Col,',')
)
select * into #tbl from stp1

--select * from #tbl

declare @Col nvarchar(max) = (select  STRING_AGG('['+ cast(ColName as Varchar(50)),'],')+']' from (select distinct ColName From #tbl) as a)

--select @Col

declare @SQL nvarchar(max) = N'select ID,'+@Col+'
From 
(select ID,ColName,Vl
from #tbl) UP 
pivot (MAX(Vl) FOR ColName IN ('+@Col+')) as v
'
exec (@SQL)

```
