# List all Docker containers
docker ps

# Create a new image from a container
docker commit -m "Update DBs 20250105" -a "Ming" 0c0cdaf2e887 mingsimage:20250105

# Display all existing images
docker images

# Save an image to a tar file
docker save -o MingsImage2025.tar mingsimage:20250105

# Load an image from a tar file
docker load -i MingsImage.tar

# Rename an image
docker tag mingsimage:20250105 <DockerUserName>/mingsimage:latest

# Push an image to a repository (login required)
docker login
docker push <DockerUserName>/mingsimage:latest

# Note: Remove all Docker containers
<!-- docker rm $(docker ps -a -q) -->

# List all Docker volumes
docker volume ls

# Inspect a specific volume
docker volume inspect sql2022-msttime