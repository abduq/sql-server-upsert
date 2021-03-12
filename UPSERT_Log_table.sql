
CREATE TABLE [Monitor].[UPSERT_log](
	[ID] [INT] IDENTITY(1,1) NOT NULL,
	[Database] [NVARCHAR](100) NULL,
	[Schema] [NVARCHAR](50) NULL,
	[Table] [NVARCHAR](50) NULL,
	[Inner_id] [NVARCHAR](200) NULL,
	[Json_record] [NVARCHAR](MAX) NULL,
	[Operation_occurred] [NVARCHAR](50) NULL,
	[Start_time] [DATETIME] NULL,
	[End_time] [DATETIME] NULL,
	[Run_time]  AS (DATEDIFF(MILLISECOND,[Start_time],[End_time])*(1.0))
)



