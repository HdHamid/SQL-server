# How to develop a Fuzzy search in SQL Server as Set base solution

All of us know that we can use NoSQL for fuzzy search or using Levenshtein algorithm as a function or using FTS for supported languages 
but I'm here to show you how do you can make your set base fuzzy search procedure

Let's start 

At the beginning, I'm going to define Input Parameters
```bash

USE TempDb
GO 


DECLARE 
@Name nvarchar(50) = N'علی', -- What you are searching for
@Prcnt decimal(5,2) = 70, -- How many percent should have similarity
@CharPositionLeft tinyint = 0, -- check if even chars shifted one place left 
@CharPositionRight tinyint = 0,-- check if even chars shifted one place right 
@SubPhrase BIT = 1 -- Check if it is a sub-phrase

```
Phrases' table
```bash

Drop table if exists #Names1 
CREATE TABLE #Names1(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](500) NULL,
)
```

Insert some persian and english strings 
```bash
Insert into #Names1
(Name)
values
(N'ابولفضل'),(N'ابوالحسن'),(N'ابوذر'),(N'احد'),(N'احمد'),(N'ادریس'),(N'ادیب'),(N'ارشاد'),(N'اسامه'),(N'اصغر'),
(N'اعتبار علی'),(N'اعلی'),(N'افضل'),(N'اقبال علی'),(N'امیر'),(N'امیرعلی'),(N'امیر حسین'),(N'امیر طاها'),(N'امیر عباس'),
(N'امیر محمد'),(N'امیر مهدی'),(N'امین'),(N'اوحد'),(N'اویس'),(N'اکبر'),(N'ایمان'),(N'باقر'),(N'برهان'),(N'بشیر')
,(N'بصیر'),(N'بلال'),(N'بها'),(N'بهلول'),(N'تراب'),(N'تقی'),(N'تمیم'),(N'توحید'),(N'توفیق'),(N'ثاقب'),(N'ثامر'),(N'جابر'),
(N'جاسم'),(N'جبار'),(N'جعفر'),(N'جلال'),(N'جلیل'),(N'جمال'),(N'جنید'),(N'جواد'),(N'خالد'),(N'خضر'),(N'خلیل'),(N'خیرالدین'),(N'خیراالله'),
(N'خیرعلی'),(N'ذبیح'),(N'ذبیح الله'),(N'ذوالفقار'),(N'رئوف'),(N'راستین'),(N'راشد'),(N'راشن'),(N'ربیع'),(N'رجا'),(N'رجب'),(N'رحمان'),(N'رحمت'),
(N'رحیم'),(N'رزاق'),(N'رسام'),(N'رسول'),(N'رشید'),(N'رضا'),(N'رضی'),(N'رفیع'),(N'رمضان'),(N'روح الله'),(N'ریاض'),(N'زائر'),(N'زاهر'),
(N'زعیم'),(N'زهیر'),(N'زکی'),(N'زید'),(N'زین الدین'),(N'زینعلی'),(N'ساجد'),(N'ساعد'),(N'سامر'),(N'سامی'),(N'سبحان'),(N'ستار'),(N'سجاد'),
(N'سحاب'),(N'سعد الدین'),(N'سعید'),(N'سلطان'),(N'سلمان'),(N'سلیم'),(N'سمیح'),(N'سمیر'),(N'سمیع'),(N'سها'),(N'سهیل'),(N'سیف الله'),
(N'شجاع الدین'),(N'شادن'),(N'شاهد'),(N'شاهر'),(N'شاکر'),(N'شبلی'),(N'شریف'),(N'شعبان'),(N'شفیع'),(N'شمس'),(N'شمس الدین'),(N'شهاب الدین'),(N'شهیر'),(N'شکرالله'),
(N'شکرعلی'),(N'شکور'),(N'شکیل'),(N'شیبان'),(N'صائب'),(N'صابر'),(N'صاحب'),(N'صادق'),(N'صاعد'),(N'صالح'),(N'صانع'),(N'صباح'),(N'صدر'),(N'صدرالدین'),(N'صدیق'),(N'صفا'),
(N'صفار'),(N'صفر'),(N'صفی'),(N'صفی الدین'),(N'صفی الله'),(N'صلاح ادین'),(N'صمد'),(N'صمصام'),(N'صمیم'),(N'صنعان'),(N'صیاد'),(N'صیام'),(N'ضرغام'),(N'ضیا'),(N'ضیا الدین'),
(N'ضیغم'),(N'طارق'),(N'طالب'),(N'طاها'),(N'طاهر'),(N'طلحه'),(N'طیب'),(N'ظفر'),(N'ظهیر'),(N'عابد'),(N'عابس'),(N'عادل'),(N'عارف'),(N'عاشور'),(N'عاصم'),(N'عامر'),
(N'عباد'),(N'عبادالله'),(N'عباس'),(N'عبدالباسط'),(N'عبدالباقی'),(N'عبدالجبار'),(N'عبدالجلیل'),(N'عبدالجواد'),(N'عبدالحسن'),(N'عبدالحسین'),(N'عبدالحق'),(N'عبدالحلیم'),(N'عبدالحمید'),
(N'عبدالخالق'),(N'عبدالرحمان'),(N'عبدالرحیم'),(N'عبدالرزاق'),(N'عبدالرسول'),(N'عبدالرشید'),(N'عبدالرضا'),(N'عبدالرفیع'),(N'عبدالستار'),(N'عبدالصمد'),(N'عبدالعزیز'),(N'عبدالعظیم'),
(N'عبدالعلی'),(N'عبدالغفار'),(N'عبدالغفور'),(N'عبدالغنی'),(N'عبدالفتاح'),(N'عبدالقادر'),(N'عبدالقاهر'),(N'عبداللطیف'),(N'عبدالله'),(N'عبدالمجید'),(N'عبدالمحمد'),
(N'عبدالملک'),(N'عبدالناصر'),(N'عبدالنبی'),(N'عبدالهادی'),(N'عبدالواحد'),(N'عبدالوهاب'),(N'عبدالکریم'),(N'عبیدالله'),(N'عدنان'),(N'عزالدین'),(N'عزت الله'),(N'عزیز'),(N'عزیزالله'),
(N'عطا'),(N'عظیم'),(N'عقیل'),(N'علا'),(N'علاء الدین'),(N'علوان'),(N'علی اصغر'),(N'علی اکبر'),(N'علیرضا'),(N'علی مراد'),(N'علیم'),(N'عماد'),(N'عمار'),(N'عمران'),
(N'عمر'),(N'عمرو'),(N'عمید'),(N'عنایت'),(N'عنایت الله'),(N'عین الدین'),(N'عین الله'),(N'عینعلی'),(N'غضنفر'),(N'غفار'),(N'غفور'),(N'غلام'),(N'غلامرضا'),(N'غیاث'),(N'غیاث الدین'),
(N'فواد'),(N'فائز'),(N'فاتح'),(N'فاضل'),(N'فاطر'),(N'فتاح'),(N'فتح الله'),(N'فتحعلی'),(N'فخرالدین'),(N'فرج'),(N'فرج الله'),(N'فرحان'),(N'فرهود'),(N'فرید'),(N'فصیح'),(N'فصیح الدین'),
(N'فضل الله'),(N'فضیل'),(N'فیاض'),(N'قائد'),(N'قادر'),(N'قاسم'),(N'قاهر'),(N'قدرت'),(N'قطب الدین'),(N'قنبر'),(N'قهار'),(N'کاظم'),(N'کامل'),(N'کرم'),(N'کرم الله'),(N'کلیم'),(N'کلیم الله'),
(N'کریم'),(N'کمال'),(N'کمال الدین'),(N'کیسان'),(N'لاوان'),(N'لبیب'),(N'لسان الدین'),(N'لطف الدین'),(N'لطف الله'),(N'لطفعلی'),(N'لطیف'),(N'لقمان'),(N'لیث'),(N'کمیل'),(N'امیررضا'),(N'یاشار'),
(N'یاشار'),(N'یاشار'),(N'یاشار'),(N'عزز'),(N'حمید'),(N'علی')
,(N'Apple'),(N'funny'),(N'Congratulations')
```

A table for Alphabets Chars in persian and english

```bash
drop table if exists #Alphabet
select IDENTITY( tinyint ) as ID,* into #Alphabet from 
(values 
 (N'ا'),(N'آ'),(N'ب') ,(N'پ'),(N'ت'),(N'ث'),(N'ج'),(N'چ'),(N'ح'),(N'خ'),(N'د'),(N'ذ'),(N'ر'),(N'ز')
,(N'ژ'),(N'س'),(N'ش'),(N'ص'),(N'ض'),(N'ط'),(N'ظ'),(N'ع'),(N'غ'),(N'ف'),(N'ق'),(N'ک'),(N'گ'),(N'ل')
,(N'م'),(N'ن'),(N'و'),(N'ه'),(N'ی')
,(N'A'),(N'B'),(N'C'),(N'D'),(N'E'),(N'F'),(N'G'),(N'H'),(N'I'),(N'K'),(N'L'),(N'M'),(N'N'),(N'O'),(N'P')
,(N'Q'),(N'R'),(N'S'),(N'T'),(N'V'),(N'X'),(N'Y'),(N'Z')
) as v (a)
```

A recursive CTE to separate each char from phrases in #Names1 table with their place
```bash
Drop table if exists #Res

;with stp1 as 
(
	select n.ID,0 as Rn,n.Name,len(n.Name)Ln,substring(n.name,1,1) as Chr,1 as position from #Names1 n 
	union all 
	select n.ID,0 as Rn,n.Name,s.Ln - 1,substring(n.name,1+s.position,1) as Strng,1+s.position as Position
	from #Names1 n inner join stp1 s on s.ID = n.ID
	where s.Ln-1 > 0 
)
```
Join with #Alphabet to get the IDs
```bash

,stp2 as 
(
	select 1 as [Type],s.ID as NameId,s.Rn,e.ID as CharId,Name,len(name) as LenString,Position,Chr from stp1 s inner join #Alphabet e on e.a = s.Chr
)
select * into #Res from stp2 
```

Separating  sub-phrases
```bash

Drop table if exists #Names


select n.id,ROW_NUMBER() over(partition by ID order by (select 0)) as Rn,s.value as Name into #Names from #Names1 n cross apply string_split(n.Name,' ') s
where Name like '% %'
```
Do kinds of stuff the same as did for #Names1 for texts with sub-phrases
```bash

;with stp1 as 
(
	select n.ID,n.Rn,n.Name,len(n.Name)Ln,substring(n.name,1,1) as Chr,1 as position from #Names n 
	union all 
	select n.ID,n.Rn,n.Name,s.Ln - 1,substring(n.name,1+s.position,1) as Strng,1+s.position as Position
	from #Names n inner join stp1 s on s.ID = n.ID and s.Rn = n.Rn
	where s.Ln-1 > 0 
)
,stp2 as 
(
	select 2 as [Type],s.ID as NameId,s.Rn,e.ID as CharId,Name,len(name) as LenString,Position,Chr from stp1 s inner join #Alphabet e on e.a = s.Chr
)
insert into #Res
select * from stp2 
```

I'm going to do everything we did before for #Names and #Names1 to the input parameter
```bash

Drop table if exists #Res2
;with stp1 as 
(
	select @Name as Name,len(@Name)Ln,substring(@Name,1,1) as Chr,1 as position 
	union all 
	select @Name,s.Ln - 1,substring(@Name,1+s.position,1) as Strng,1+s.position as Position
	from stp1 s 
	where s.Ln-1 > 0 
),stp2 as 
(
	select e.ID as CharId,Name,len(name) as LenString,Position,Chr from stp1 s inner join #Alphabet e on e.a = s.Chr
)
select * into #res2 from stp2 
```

Search the input parameter 
```bash
drop table if exists #stp1
;with stp1 as 
(
	select 'FuzzyType1' as FuzzyType ,r.*,r2.LenString as SrchStringLen
	from #res2 r2 
	inner join #Res r on r.CharId = r2.CharId and r.position between r2.position - @CharPositionLeft and r2.position + @CharPositionRight and [Type] = 1
	Union ALL
	select 'FuzzyType2' as FuzzyType ,r.*,r2.LenString as SrchStringLen
	from #res2 r2 
	inner join #Res r on r.CharId = r2.CharId and r.position between r2.position - @CharPositionLeft and r2.position + @CharPositionRight and @SubPhrase = 1  and [Type] = 2
)
select * into #stp1 from stp1
``` 
Join with #Names1 to find the phrases
```bash
drop table if exists #stp2
select s.*,n.Name as OrgName,len(n.Name) as LenOrgName,Count(1) over(partition by NameId,rn,FuzzyType) as Cnt into #stp2
from #stp1 s
 inner join #Names1 n on n.ID = s.NameId
```
Calculating similarity percentage
```bash
drop table if exists #stp3
select s.*,cnt*100.00/(iif(LenOrgName>SrchStringLen,LenOrgName,SrchStringLen)*1.00) as Prcnt
into #stp3
from #stp2 s where FuzzyType = 'FuzzyType1'
UNION ALL 
select s.*,cnt*100.00/(iif(LenString>SrchStringLen,LenString,SrchStringLen)*1.00) as Prcnt
from #stp2 s where FuzzyType = 'FuzzyType2'

select NameId,OrgName from #stp3
where Prcnt >= @Prcnt
group by NameId,OrgName
order by AVG(Prcnt) desc
```
