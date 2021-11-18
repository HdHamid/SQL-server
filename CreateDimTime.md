# How to create DimTime

```bash

;with Hrs as 
(
	select 0 as HH
	Union all
	select HH+1 from Hrs 
	where hh<23
)
, Mnts as 
(
	select 0 as mm
	Union all
	select mm+1 from Mnts 
	where mm<59
)
, Scnds as 
(
	select 0 as ss
	Union all
	select ss+1 from Scnds 
	where ss<59
)
select ROW_NUMBER()over(order by HH,mm,ss) as ID,
	HH as HHInt,
	mm as mmInt,
	ss as ssInt,
	replicate('0',2-len(HH))+cast(HH as Varchar(2)) as HHChr,
	replicate('0',2-len(mm))+cast(mm as Varchar(2)) as mmChr,
	replicate('0',2-len(ss))+cast(ss as Varchar(2)) as ssChr,
	replicate('0',2-len(HH))+cast(HH as Varchar(2))+':'+replicate('0',2-len(mm))+cast(mm as Varchar(2))+':'+replicate('0',2-len(ss))+cast(ss as Varchar(2))+'.000'  as [Time]
from Hrs h 
	cross join Mnts m
	cross join Scnds s
order by HH,mm,ss

```
