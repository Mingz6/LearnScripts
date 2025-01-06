# Setting Up SQL Server 2022 in a Docker Container and Restoring a Database

## Step 1: Prerequisites
- Install **Docker Desktop**
- Install **Azure Data Studio**

## Step 2: Configure Docker Resources
Ensure your Docker container meets the minimum requirements:
- **CPUs**: 2 (6 recommended)
- **RAM**: 6GB (8GB recommended)
- **Disk Image Size**: 120GB (150GB recommended)

To configure these settings, navigate to **Docker Desktop > Settings > Resources > Advanced**.

## Step 3: Launch a Docker Container for SQL Server 2022
The following command creates and starts a new Docker container named `sql2022-edmT` with SQL Server 2022. It sets the SA password, maps port 1433, configures the timezone to `America/Edmonton`, and mounts a volume for persistent storage.

```shell
sudo docker run \
   -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=<Password>' \
   -p 1433:1433 --name sql2022-edmT --hostname sql2022-edmT \
   --platform linux/amd64 \
   --restart always \
   -e 'TZ=America/Edmonton' \
   -v sql2022-edmtime:/var/opt/mssql \
   -d \
   mcr.microsoft.com/mssql/server:2022-latest
```

### Note
If your connection string in `secrets.json` doesn’t work, ensure it includes the port:
```
Data Source=localhost,1433;Initial Catalog=YourDb;User Id=sa;Password=<password>;
```

## Step 4: Connect to the SQL Server Instance
1. Open **Azure Data Studio**.
2. Click **New Connection**.
3. Enter the following details:
   - **Server**: `localhost`
   - **Authentication Type**: SQL Login
   - **User Name**: `sa`
   - **Password**: `<password>`
4. Click **Connect**.

## Step 5: Restore a Database

### Step 5.1: Restore a BACPAC File
1. Open Azure Data Studio.
2. Use the "Import Data-tier Application" wizard to restore the BACPAC file.

### Step 5.2: Restore a BAK File

#### Copy the Backup File to the Docker Container
1. Retrieve the Docker container ID:
   ```shell
   docker ps
   ```
2. Copy the backup file into the container:
   ```shell
   docker cp YourDb.bak <container_id>:/YourDb.bak
   ```

#### Restore the Database
1. Open **Azure Data Studio** and connect to the SQL Server instance.
2. Use the "Restore Database" option to restore the database from the backup file.

## Step 6: Clean Up
After restoring the database, remove the backup file from the container to save space:
```shell
docker exec -u root 0c0cdaf2e887 rm /APTIFY.bak


docker cp APTIFY.bak 0c0cdaf2e887:/APTIFY.bak