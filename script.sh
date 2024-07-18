#!/bin/sh
set -a # automatically export all variables
echo "Sourcing .env file..."
if source .env; then
    echo "Successfully sourced .env."
else
    echo "Failed to source .env."
    exit 1
fi
set +a

echo "Checking out to a new test branch..."
NEW_BRANCH="test-$(date +%Y%m%d%H%M%S)"
if git checkout -b "$NEW_BRANCH"; then
    echo "Successfully checked out new branch $NEW_BRANCH."
else
    echo "Failed to checkout new branch $NEW_BRANCH."
    exit 1
fi

echo "Pulling the latest changes from the develop branch..."
if git pull origin develop; then
    echo "Successfully pulled from develop."
else
    echo "Failed to pull from develop."
    exit 1
fi

echo "Stopping the currently running container..."
if docker compose down; then
    echo "Successfully stopped containers."
else
    echo "Failed to stop containers."
    exit 1
fi

echo "Pulling the latest Docker image..."
if docker compose -f docker-compose.yml pull; then
    echo "Successfully pulled latest Docker image."
else
    echo "Skipping initial pull (assuming first time setup)."
fi

echo "Pulling the latest Docker image for development..."
if docker compose -f docker-compose.dev.yml pull; then
    echo "Successfully pulled latest Docker images for development."
else
    echo "Failed to pull latest Docker images for development."
    exit 1
fi

echo "Starting the development environment using the development script..."
if bash scripts/compose-dev.script.sh; then
    echo "Successfully started the development environment."
else
    echo "Failed to start the development environment."
    exit 1
fi

# Insert your build, test, and validation commands here with similar if-then-else logic for feedback

echo "Cleaning up old Docker images and containers..."
if docker system prune -af; then
    echo "Successfully cleaned up Docker images and containers."
else
    echo "Failed to clean up Docker images and containers."
    exit 1
fi

echo "Merging $NEW_BRANCH into develop..."
if git checkout develop && git merge "$NEW_BRANCH" --no-ff; then
    echo "Successfully merged $NEW_BRANCH into develop."
else
    echo "Failed to merge $NEW_BRANCH into develop. Please check for conflicts or permissions."
    exit 1
fi

echo "Deleting the test branch $NEW_BRANCH..."
if git branch -d "$NEW_BRANCH"; then
    echo "Successfully deleted the test branch $NEW_BRANCH."
else
    echo "Failed to delete the test branch $NEW_BRANCH. It may have already been deleted or not fully merged."
fi
