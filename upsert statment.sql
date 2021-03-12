
CREATE PROCEDURE [dbo].[UPSERT] 
  @database NVARCHAR(200) = 		  NULL
, @schema NVARCHAR(200) = 		  NULL
, @table_name NVARCHAR(200)= 	  NULL
, @json_record NVARCHAR(MAX) = 	  NULL
, @key_column NVARCHAR(200)= 	  NULL

AS 




/*-----------------------------------------------------------------------------------------
____ ____ _  _ _ ____ _ ____ _  _    _  _ _ ____ ___ ____ ____ _   _
|__/ |___ |  | | [__  | |  | |\ |    |__| | [__   |  |  | |__/  \_/
|  \ |___  \/  | ___] | |__| | \|    |  | | ___]  |  |__| |  \   |

Date					Changed By			Description
----------				-------------		---------------------------------------------------------
2021-02-22				Abdullah Aqeeli		Initial script
2021-03-02				Abdullah Aqeeli		Handle NULL Columns
2021-03-05				Abdullah Aqeeli		Support Arabic characters 
2021-03-08				Abdullah Aqeeli		add logging

------- USAGE:

- This sotred proc will take 1 json record and UPSERT it into the specified table in the parameters
- It should check if target table exists
- It should check if JSON is valid
- To escape single qoutation use four single qoutation ''''

------- Assumptions:

	1- The structure of the json should matche the target table's in terms of names and order
	2- It should handle ignore extra columns in the json if they're added at the end
	3- You'd use this to do more inserts and less updates
	

------- EXAMPLE:

UPSERT @database = 'LasVegas'
, @schema = 'dbo'
, @table_name = 'thatOneTable'
, @json_record  = 
'{"ID":1,
"thisColumn":"doing stuff",
"thatColumn":"making stuff",
"someColumn":"milking stuff",
"thisIsFun":"it''''s fun actually",
"dirtyNun":null}'
, @key_column = 'ID'





*/------------------------------------------------------------------------------------------



declare 

--------------------------------------
  @sql_statment nvarchar(max)= N''
, @main_table_sql_statment nvarchar(max)= N''
, @update_table_sql_statment nvarchar(max) = N''
, @starttime AS DATETIME = GETDATE()
, @endtime AS datetime = GETDATE()
, @operation_occurred AS NVARCHAR(200)
, @table_exists int =0
--------------------------------------


-- log START:
set @starttime = GETDATE()


----- A: Error Checking:

--[1]: Validate JSON format

if (isjson(@json_record)<1)
begin
RAISERROR('Not a valid JSON',16,1)
end


--[2]: Check if Target table exists

set @sql_statment= 'select @check = count(*) from '+ @database +'.INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA= '''+@schema+''' and TABLE_NAME= '''+@table_name+''''
exec sys.sp_executesql 
@sql_statment,N'@check int out',
@table_exists out

set @sql_statment =N''

if(@table_exists < 1) 
begin
RAISERROR('Table Does Not Exist',16,1)
end


--[3]: Check if JSON fields matches table metadata


---- TODO :)


-----------------------------------------------
-----------------------------------------------
-----------------------------------------------



----- B: Prepare insertion table:


--[1]: Create Temp Table

set @sql_statment = 'select top 10 * from '+@database+'.'+@schema+'.'+@table_name
set @main_table_sql_statment = '
---UPSERTing

create table #theTable ( '
select @main_table_sql_statment= @main_table_sql_statment + ' '+name+' '+system_type_name+' ,' from sys.dm_exec_describe_first_result_set(@sql_statment, NULL, 0) order by column_ordinal

--- get rid off the trailing comma and add a bracket
select @main_table_sql_statment = stuff(@main_table_sql_statment,len(@main_table_sql_statment),1,' )    

')



--[2]: Prepare insert statment into temp table

set @main_table_sql_statment = @main_table_sql_statment + ' 

insert into #theTable 
values (
'
select @main_table_sql_statment =@main_table_sql_statment+ iif(j.Value is null,' null,','cast(N''' +j.Value+''' as '+t.system_type_name+') ,' )
 from sys.dm_exec_describe_first_result_set(@sql_statment, NULL, 0) t
 join openjson(@json_record) j on t.[name] COLLATE DATABASE_DEFAULT = j.[Key] COLLATE database_default
 
 --- get rid off the trailing comma and add a bracket
 select @main_table_sql_statment = stuff(@main_table_sql_statment,len(@main_table_sql_statment),1,' )    

')




----- C: Do the upsert:


--[1]: prepare update statment just in case?

select @update_table_sql_statment = @update_table_sql_statment + ' ' +t.name +' = '+ 'tmp.'+ name+',' from sys.dm_exec_describe_first_result_set(@sql_statment, null, 0) t

--- get rid off the trailing comma and add a bracket
select @update_table_sql_statment = stuff(@update_table_sql_statment,len(@update_table_sql_statment),1,' ')


--[2]: Upsert (it is more optimized for frequent inserts and less frequnet updates):

SET @main_table_sql_statment = + @main_table_sql_statment + '  

BEGIN TRANSACTION;
set @operation = ''INSERTED''
INSERT INTO '  +@database+'.'+@schema+'.'+@table_name  + ' 
  SELECT * from #theTable t
  WHERE NOT EXISTS
  (
    SELECT 1 FROM ' + @database+'.'+@schema+'.'+@table_name  +' with (UPDLOCK, SERIALIZABLE)
      WHERE '+@key_column+' = t.' +@key_column+'  );
 
IF @@ROWCOUNT = 0
BEGIN
  UPDATE '+ @database+'.'+@schema+'.'+@table_name  + ' SET '+
  @update_table_sql_statment
  +
  
 'from (select * from #theTable) as tmp WHERE '+@table_name+'.'+@key_column+' = tmp.' +@key_column+'
 SET @operation = ''UPDATED''
END

COMMIT TRANSACTION;

Select @operation as result

drop table if exists #theTable
' 

PRINT @main_table_sql_statment
EXECUTE sp_executesql @main_table_sql_statment, N'@operation nvarchar(200) OUTPUT', @operation_occurred  OUTPUT


--[3]: log stuff
INSERT INTO Monitor.UPSERT_log
(
   
    [Database],
    [Schema],
    [Table],
	Inner_ID,
    Json_record,
    Operation_occurred,
    Start_time,
    End_time
)
VALUES
(   
    @database,       -- Database - nvarchar(100)
    @schema,       -- Schema - nvarchar(50)
    @table_name,       -- Table - nvarchar(50)
	(SELECT TOP 1 CAST(Value AS NVARCHAR(200)) FROM OPENJSON(@json_record)),
    @json_record,       -- Json_record - nvarchar(max)
    @operation_occurred,       -- Operation_occurred - nvarchar(50)
    @starttime, -- Start_time - datetime
    GETDATE()  -- End_time - datetime
	
    )
