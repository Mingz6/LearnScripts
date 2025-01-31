# Installing Azurite in Docker Desktop on Mac (Apple Silicon)

Azurite is an emulator for Azure Storage services, allowing local development and testing. Here's how to set it up using Docker on a Mac with Apple Silicon:

## 1. Check Docker Desktop Installation

Ensure Docker Desktop for Mac is installed. Download it from [Docker's official website](https://www.docker.com/products/docker-desktop) if necessary. Docker Desktop supports Apple Silicon from version 3.3.1 onwards.

## 2. Pull and Run the Azurite Docker Image

Run the following command to pull and start the Azurite container:

```bash
docker run -d --restart always -p 10000:10000 -p 10001:10001 -p 10002:10002 --name azurite mcr.microsoft.com/azure-storage/azurite
```

### Explanation of Parameters:
- `-d`: Detaches the container, allowing it to run in the background.
- `--restart always`: Ensures the container restarts automatically if stopped.
- `-p`: Maps container ports to host ports.
- `--name azurite`: Sets the container's name for easier management.

## 3. Optional: Configure Persistent Storage

For persistent data storage, mount a volume to the container:

```bash
docker run -d --restart always -p 10000:10000 -p 10001:10001 -p 10002:10002 -v ~/.azurite_data:/data --name azurite mcr.microsoft.com/azure-storage/azurite
```

Replace `~/.azurite_data` with your desired local storage path. This ensures that data persists even if the container is stopped or removed.

## 4. Verify Container Status

To confirm that the Azurite container is running, list the active containers:

```bash
docker ps
```

## 5. Access Azurite Services

You can access Azurite's services using the following localhost URLs:

- **Blob service**: [http://localhost:10000](http://localhost:10000)
- **Queue service**: [http://localhost:10001](http://localhost:10001)
- **Table service**: [http://localhost:10002](http://localhost:10002)

By following these steps, you'll have Azurite running in Docker on your Mac, ready for local development and testing against Azure Storage services.
