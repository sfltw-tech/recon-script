#!/bin/bash
  
echo "Remove stopped containers"
docker container prune -f

echo "Remove unused images"
docker image prune -f -a

echo "Remove unused volumes"
docker volume prune -f

echo "Remove build cache"
docker builder prune -f
