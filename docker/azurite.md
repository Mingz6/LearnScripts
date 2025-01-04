Installing Azurite in Docker Desktop on Mac (Apple Silicon)

Azurite is an emulator for Azure Storage services, allowing local development and testing. Here's how to set it up using Docker on a Mac with Apple Silicon:

1. Check Docker Desktop Installation
Ensure Docker Desktop for Mac is installed. Download it from Docker's official website if necessary. Docker Desktop supports Apple Silicon from version 3.3.1 onwards.

2. Pull and run the Azurite Docker Image

`docker run -d --restart always -p 10000:10000 -p 10001:10001 -p 10002:10002 --name azurite mcr.microsoft.com/azure-storage/azurite`

-d detaches the container (runs in the background).
-p maps container ports to host ports.
--name azurite sets the container's name.

3. Optional: Configure Persistent Storage
For persistent data storage, mount a volume to the container:

`docker run -d -p 10000:10000 -p 10001:10001 -p 10002:10002 -v <~/.azurite_data>:/data --name azurite mcr.microsoft.com/azure-storage/azurite`
Replace <~/.azurite_data> with your desired local storage path.

4. Verify Container Status
List the running containers to check if Azurite is running:
`docker ps`

5. Access Azurite Services
Access Blob, Queue, and Table services through mapped localhost ports:

Blob service: http://localhost:10000
Queue service: http://localhost:10001
Table service: http://localhost:10002

By following these steps, you'll have Azurite running in Docker on your Mac, ready for local development and testing against Azure Storage services.