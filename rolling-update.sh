#!/bin/bash

# Define array of server IP addresses
hostnames=("host1" "host2" "host3")
servers=("10.0.0.1" "10.0.0.2" "10.0.0.3")

# Define common username, image name, and service name
username="ssh username with docker privilages (sudo usermod -aG docker your_username)"
image_name="image name, image need to be public or logged in with your_username (sudo - u your_username docker login)"
service_name="swarm service name, needs to be deployed as global"

#!/bin/bash

# Function to check if the container is healthy
is_container_healthy() {
    local server="$1"
    local container_id="$2"
    local health_status=$(ssh "$username@$server" "docker inspect --format='{{.State.Health.Status}}' $container_id")
    echo "$(date +"%Y-%m-%d %H:%M:%S") - health_status for: $container_id is $health_status"
    [ "$health_status" == "healthy" ]
}

# Function to perform the health check for a server and container
perform_health_check() {
    local server="$1"
    local container_id="$2"

    while true; do
        # Wait a bit and get newly created container
        sleep 10
        container_id=$(ssh "$username@$server" "docker ps -q -f 'ancestor=$image_name'")

        # Wait for the container to be created and become healthy, check every 30 seconds for a maximum of 5 minutes
        wait_time=0
        while [[ $wait_time -lt 300 ]]; do
            if is_container_healthy "$server" "$container_id"; then
                echo "$(date +"%Y-%m-%d %H:%M:%S") - $server: Container created and healthy successfully"
                return 0  # Success
            fi
            echo "$(date +"%Y-%m-%d %H:%M:%S") - $server: Waiting for container to become healthy, sleeping for 30 seconds"
            sleep 30
            wait_time=$((wait_time + 30))
        done

        # If the container is still not healthy, restart Docker service
        echo "$(date +"%Y-%m-%d %H:%M:%S") - $server: Container not healthy within 5 minutes, restarting Docker service"
        ssh "$username@$server" "sudo systemctl restart docker"
    done
}



# Iterate over servers and hostnames simultaneously
for i in "${!servers[@]}"; do
    server="${servers[$i]}"
    hostname="${hostnames[$i]}"

    echo "$(date +"%Y-%m-%d %H:%M:%S") - Processing server: $server (Docker Node: $hostname)"

    echo "$(date +"%Y-%m-%d %H:%M:%S") - $server: Pulling latest image $image_name"

    # Docker pull image
    ssh "$username@$server" "docker pull $image_name"

    echo "$(date +"%Y-%m-%d %H:%M:%S") - $server: Pulled latest image $image_name"

    # Get container ID for the service on the drained node
    container_id=$(ssh "$username@$server" "docker ps -q -f 'ancestor=$image_name'")

    echo "$(date +"%Y-%m-%d %H:%M:%S") - $server: Stopping container $container_id"

    # Kill the container on the drained node
    ssh "$username@$server" "docker stop -t 300 $container_id"

    echo "$(date +"%Y-%m-%d %H:%M:%S") - $server: $container_id stopped, waiting for container creation and health"

    # Perform health check
    perform_health_check "$server" "$container_id"


done

echo "Task completed successfully."
