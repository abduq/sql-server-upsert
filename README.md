# SQL Server UPSERT statment

An upsert statement for sql server. 

## Motivation
When using Apache Nifi as a replication tool to replicate data from a source database to a destination SQL Server database. Instead of building a complicated workflow that handles Insert/Update operation, I decided to deal with each row as a single event and UPSERT it directly into the required destination table.

## How does it work? 

A stored procedure that takes Database name, schema name, table name, search column (primary key), and a JSON object
and performs an UPSERT based on the search column. If the primary key exists it updates the exiting record, if it does not exits it inserts it.   

*Make sure to escape single quotation inide your json values with four single qoutations (''''). This is due to using dynamic sql inside the stored procedure, so single qoutations would need double escaping.

## Assumptions:

1- The structure of the json should match the target table's in terms of column names, order and data types.   
2- It should ignore extra columns in the json if they're added at the end (in case of target schema changes).   
3- You'd be using this to do more inserts and less updates.   
