docker ps

# Docker Commit ==> build a new image from a container
docker commit -m "Update DBs 20250105" -a "Ming" 0c0cdaf2e887 mingsimage:20250105

# show all existing images
docker images

# Save image to tar file
docker save -o MingsImage2025.tar mingsimage:20250105

# Load Image ==> Share it with others
docker load -i MingsImage.tar

# docker tag <image_id> <new_image_name>:<tag> ==> rename the image
docker tag mingsimage:20250105 kyo620724/mingsimage:latest

# docker push must have login first and the image name must be in the format of <username>/<image_name>:<tag>
docker login
docker push kyo620724/mingsimage:latest

# Attention: Remove all Docker containers
<!-- docker rm $(docker ps -a -q) -->

# list all volumes
docker volume ls

# check the volume details
docker volume inspect sql2022-edmtime