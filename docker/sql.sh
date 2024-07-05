# Setup the docker volume for the SQL Server 2022 Edmonton instance
sudo docker run -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=<password>' \
   -p 1433:1433 --name sql2022-edmT --hostname sql2022-edmT \
   --platform linux/amd64 \
   --restart always \
   -e 'TZ=America/Edmonton' \
   -v sql2022-edmtime:/var/opt/mssql \
   -d \
   mcr.microsoft.com/mssql/server:2022-latest

# In your docker you should then see that there is an sql instance up and running. Now, hit the cog in the top right, go to resources and change Disk image size to at least 60GB, probably 120GB to be sure, hit apply and restart.
# From there you should be able to create a new database
# IF that doesn't work, you can hit the script button and compare it to the file bellow. You might have to add WITH REPLACE in order Azure Data Studio to populate the database.
USE [master]
RESTORE DATABASE [YourDb] 
FROM  DISK = N'/<YourDb.bak>' 
WITH REPLACE, FILE = 1,  
MOVE N'<YourDb_Data.mdf>' 
TO N'/var/opt/mssql/data/<YourDb_Data.mdf>',  
MOVE N'YourDb_Log.ldf' 
TO N'/var/opt/mssql/data/<YourDb_Log.ldf>',  
NOUNLOAD,  STATS = 5
# The connection string in your secrets.json should still work, but if it doesn't, you might have to add the port to the connection string like bellow:
Data Source=localhost,1433;Initial Catalog=YourDb;User Id=sa;Password=<password>;

# Get docker ID
# e.g. 7edd10a3808d
docker ps

# Copy BAK file to the docker container
docker cp YourDb.BAK 7edd10a3808d:/YourDb.BAK

# Restore the BAK file to the Data Studio
# Delete BAK file from the docker container
docker exec -u root 7edd10a3808d rm /YourDb.BAK
