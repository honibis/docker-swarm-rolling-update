# docker-swarm-rolling-update
A simple yet effective sh script to process rolling updates for a docker swarm service

# Define array of server IP addresses
hostnames=("host1" "host2" "host3")
servers=("10.0.0.1" "10.0.0.2" "10.0.0.3")

# Define common username, image name, and service name
username="ssh username with docker privilages (sudo usermod -aG docker your_username)"
image_name="image name, image need to be public or logged in with your_username (sudo - u your_username docker login)"
service_name="swarm service name, needs to be deployed as global"
