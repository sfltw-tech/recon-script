#!/bin/bash
  
# Configuration
# Set the age threshold (in days) for images to be deleted
AGE_THRESHOLD=14

# Set the target repositories (optional)
# Leave it empty to delete images from all repositories
TARGET_REPOSITORIES=("sephora-asia/reconn-consistency-backend-service" "sephora-asia/reconn-platform-frontend")

# Docker registry URL and credentials (if needed)
DOCKER_REGISTRY_URL="10.239.40.165:5000"

# Docker registry container name
DOCKER_REGISTRY_CONTAINER_NAME="distracted_goldstine"

# Delete images based on age and repository
delete_old_images() {
  echo "Deleting images older than $AGE_THRESHOLD days from $DOCKER_REGISTRY_URL"

  # Get the list of repositories
  ALL_REPOSITORIES=$(curl -s -X GET "http://$DOCKER_REGISTRY_URL/v2/_catalog" | jq -r '.repositories[]')

  # Filter repositories based on target repositories
  if [ ${#TARGET_REPOSITORIES[@]} -gt 0 ]; then
    REPOSITORIES=($(for repo in "${ALL_REPOSITORIES[@]}"; do for target in "${TARGET_REPOSITORIES[@]}"; do [[ $repo == $target ]] && echo $repo; done; done))
  else
    REPOSITORIES=("${ALL_REPOSITORIES[@]}")
  fi


  # Iterate through the repositories
  for REPO in "${REPOSITORIES[@]}"; do
    echo "Processing repository: $REPO"

    # Get the list of tags for the current repository
    TAGS_JSON=$(curl -s -X GET "https://$DOCKER_REGISTRY_URL/v2/$REPO/tags/list")

    # Check if tags are not null
    if [[ $(jq -r '.tags' <<< "$TAGS_JSON") != "null" ]]; then
      TAGS=$(jq -r '.tags[]' <<< "$TAGS_JSON")

      # Get the list of tags for the current repository
      #TAGS=$(curl -s -X GET "http://$DOCKER_REGISTRY_URL/v2/$REPO/tags/list" | jq -r '.tags[]')

      # Iterate through the tags
      for TAG in $TAGS; do
        # Get the image creation timestamp
        CREATED_AT=$(curl -s -X GET "http://$DOCKER_REGISTRY_URL/v2/$REPO/manifests/$TAG" | jq -r '.history[0].v1Compatibility' | jq -r '.created')

        # Calculate the age of the image
        CREATED_AT_SECONDS=$(date -d "$CREATED_AT" +%s) 
        CURRENT_TIME_SECONDS=$(date +%s)                                                                                                                                                                                       
        AGE_DAYS=$(( (CURRENT_TIME_SECONDS - CREATED_AT_SECONDS) / 86400 ))                                                                                                                                                    
                                                                                                                                                                                                                               
        # Delete the image if it's older than the threshold                                                                                                                                                                    
        if [ $AGE_DAYS -gt $AGE_THRESHOLD ]; then                                                                                                                                                                              
          echo "Deleting image: $REPO:$TAG (Age: $AGE_DAYS days)"                                                                                                                                                              
          IMAGE_DIGEST=$(curl -I -s -X GET "http://$DOCKER_REGISTRY_URL/v2/$REPO/manifests/$TAG" | grep -i 'Docker-Content-Digest:' | awk '{ print $2 }' | tr -d '\r')                                                         
          curl -s -X DELETE "http://$DOCKER_REGISTRY_URL/v2/$REPO/manifest/$IMAGE_DIGEST"                                                                                                                                      
        fi                                                                                                                                                                                                                     
      done                                                                                                                                                                                                                     
    fi                                                                                                                                                                                                                         
    end                                                                                                                                                                                                                        
  done                                                                                                                                                                                                                         
}                                                                                                                                                                                                                              
                                                                                                                                                                                                                               
# Run garbage collection                                                                                                                                                                                                       
run_garbage_collection() {                                                                                                                                                                                                     
  echo "Running garbage collection for $DOCKER_REGISTRY_CONTAINER_NAME"                                                                                                                                                        
  docker exec -it "$DOCKER_REGISTRY_CONTAINER_NAME" bin/registry garbage-collect /etc/docker/registry/config.yml                                                                                                               
}                                                                                                                                                                                                                              
                                                                                                                                                                                                                               
# Run the function to delete old images                                                                                                                                                                                        
delete_old_images                                                                                                                                                                                                              
                                                                                                                                                                                                                               
# Run the function to execute garbage collection                                                                                                                                                                               
run_garbage_collection  