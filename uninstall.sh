#!/bin/bash

# SeAT Docker Uninstall Script
# This script stops and removes all containers, networks, and optionally volumes
# for the SeAT Docker Compose stack.

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

# Check if docker-compose.yml exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: docker-compose.yml not found at ${COMPOSE_FILE}${NC}"
    exit 1
fi

echo -e "${YELLOW}SeAT Docker Uninstall Script${NC}"
echo "================================"
echo ""

# Check if stack is running
if ! docker compose -f "$COMPOSE_FILE" ps -q > /dev/null 2>&1; then
    echo -e "${YELLOW}No running containers found. Stack may already be stopped.${NC}"
    echo ""
fi

# Stop and remove containers and networks
echo -e "${YELLOW}Stopping and removing containers and networks...${NC}"
docker compose -f "$COMPOSE_FILE" down

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Containers and networks removed successfully${NC}"
else
    echo -e "${RED}✗ Error removing containers and networks${NC}"
    exit 1
fi

echo ""

# Ask about volumes
echo -e "${YELLOW}Do you want to remove volumes as well?${NC}"
echo "This will delete:"
echo "  - Database data (mariadb-data)"
echo "  - SeAT storage (seat-storage)"
echo "  - Redis data (redis-data)"
echo ""
echo -e "${RED}WARNING: This will permanently delete all data!${NC}"
read -p "Remove volumes? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing volumes...${NC}"
    docker compose -f "$COMPOSE_FILE" down -v
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Volumes removed successfully${NC}"
    else
        echo -e "${RED}✗ Error removing volumes${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Volumes preserved. Data will be available if you redeploy.${NC}"
fi

echo ""
echo -e "${GREEN}Uninstall complete!${NC}"

