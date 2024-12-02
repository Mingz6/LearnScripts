# This script sets up a SQL Server 2022 instance in a Docker container and restores a database from a backup file.

# Step 1: Launch a Docker container for SQL Server 2022
# This command creates and starts a new Docker container named 'sql2022-edmT' with SQL Server 2022.
# It sets the SA password, maps port 1433, sets the timezone to America/Edmonton, and mounts a volume for persistent storage.
sudo docker run -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=<password>' \
   -p 1433:1433 --name sql2022-edmT --hostname sql2022-edmT \
   --platform linux/amd64 \
   --restart always \
   -e 'TZ=America/Edmonton' \
   -v sql2022-edmtime:/var/opt/mssql \
   -d \
   mcr.microsoft.com/mssql/server:2022-latest

# Note: After running the container, you should see the SQL instance up and running in Docker.
# To adjust resources, go to Docker settings > Resources and set the Disk image size to at least 60GB (120GB recommended), then apply and restart.

# Step 2: Restore a Database
# This SQL command restores a database from a backup file.
# Replace '<YourDb>' and '<YourDb.bak>' with your database and backup file names, respectively.
# The 'WITH REPLACE' option is used to overwrite any existing database.
USE [master]
RESTORE DATABASE [YourDb] 
FROM  DISK = N'/<YourDb.bak>' 
WITH REPLACE, FILE = 1,  
MOVE N'<YourDb_Data.mdf>' 
TO N'/var/opt/mssql/data/<YourDb_Data.mdf>',  
MOVE N'YourDb_Log.ldf' 
TO N'/var/opt/mssql/data/<YourDb_Log.ldf>',  
NOUNLOAD,  STATS = 5

# Note: If the connection string in your secrets.json doesn't work, ensure it includes the port as shown below:
Data Source=localhost,1433;Initial Catalog=YourDb;User Id=sa;Password=<password>;

# Step 3: Prepare for Database Restoration
# Retrieve the Docker container ID of the SQL Server instance. e.g. 7edd10a3808d
docker ps

# Copy the backup file into the Docker container.
# Replace 'YourDb.BAK' with the name of your backup file and '7edd10a3808d' with your container's ID.
docker cp <YourDb>.BAK <7edd10a3808d>:/<YourDb>.BAK

# Step 4: Clean Up
# After restoring the database, remove the backup file from the container to save space.
docker exec -u root <7edd10a3808d> rm /<YourDb>.BAK