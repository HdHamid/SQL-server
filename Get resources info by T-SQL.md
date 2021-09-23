# Get resources info by T-SQL
## Memory
```bash
   declare @CurrMemory int
   declare @SqlMaxMemory int
   declare @OSMaxMemory int
   declare @OSAvailableMemory int 
 
   -- #SQL memory
   SELECT 
      @CurrMemory = (committed_kb/1024),
      @SqlMaxMemory = (committed_target_kb/1024)           
   FROM sys.dm_os_sys_info;
   
   -- #OS memory
   SELECT 
      @OSMaxMemory = (total_physical_memory_kb/1024),
      @OSAvailableMemory = (available_physical_memory_kb/1024) 
   FROM sys.dm_os_sys_memory;
   
   select    
     @CurrMemory	AS SQL_current_Memory_usage_mb	
   , @SqlMaxMemory	AS SQL_Max_Memory_target_mb		
   , @OSMaxMemory	AS OS_Total_Memory_mb			
   , @OSAvailableMemory	AS OS_Available_Memory_mb	
   , FORMAT(@CurrMemory*1.00/@OSMaxMemory,'0.##%') AS SqlUsagePrcnt
```

## CPU

```bash
declare @ms_now bigint  

select @ms_now = ms_ticks from sys.dm_os_sys_info;

declare @cnt int = 1

;with stp1 as 
(
select top (@cnt)
	record_id,            
	dateadd(ms, -1 * (@ms_now - [timestamp]), GetDate()) as EventTime,
	SQLProcessUtilization,
	SystemIdle,
	100 - SystemIdle - SQLProcessUtilization as OtherProcessUtilization            
from (            
		select record.value('(./Record/@id)[1]', 'int') as record_id,           
		record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') as SystemIdle,            
		record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') as SQLProcessUtilization,            
		timestamp            
		from (            
			select timestamp, convert(xml, record) as record            
			from sys.dm_os_ring_buffers            
			where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'            and record like '%SystemHealth%'
			) as x    
	) as y    
	Order By record_id Desc 
)
	select 
	 COUNT(1) as TraceCount
	,Max(EventTime) as CurrentTime
	,DateDiff(MINUTE,Min(EventTime),Max(EventTime)) as TimeRange_Minute
	,AVG(SQLProcessUtilization) as SQLProcessUtilization_prcnt
	,AVG(SystemIdle) as SystemIdle_prcnt
	,AVG(OtherProcessUtilization) as OtherProcessUtilization_prcnt
	from stp1


```
