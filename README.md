# sql-server-upsert

An upsert statement for sql server. 

How it works? 

It should take Database name, schema name, table name, search column and a JSON object
and perform an UPSERT based on the search column.

Assumptions:

	1- The structure of the json should match the target table's in terms of names and order and data types.
	2- It should ignore extra columns in the json if they're added at the end (in case of target schema changes)
	3- You'd be using this to do more inserts and less updates
