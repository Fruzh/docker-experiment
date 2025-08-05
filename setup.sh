#!/bin/bash

# Docker Laravel Setup Script
# Author: Fruzh
# Description: Automated setup for Laravel with Docker (Apache + MySQL)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Docker installation
check_docker() {
    print_status "Checking Docker installation..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed!"
        print_status "Installing Docker..."
        sudo apt update
        sudo apt install -y docker.io docker-compose
        sudo systemctl start docker
        sudo systemctl enable docker
        print_success "Docker installed successfully!"
    else
        print_success "Docker is already installed"
    fi
    
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed!"
        print_status "Installing Docker Compose..."
        sudo apt install -y docker-compose
        print_success "Docker Compose installed successfully!"
    else
        print_success "Docker Compose is already installed"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Function to get user input for DB config
get_db_config() {
    print_status "Masukkan konfigurasi database untuk Docker dan Laravel (.env root project):"
    read -p "Nama database (default: laravel): " DB_NAME
    DB_NAME=${DB_NAME:-laravel}
    read -p "Password database MySQL (default: root): " DB_PASS
    DB_PASS=${DB_PASS:-root}
}

# Function to configure environment in parent Laravel folder
configure_env() {
    print_status "Configuring .env di root project Laravel ($PARENT_DIR)..."
    ENV_PATH="$PARENT_DIR/.env"
    ENV_EXAMPLE_PATH="$PARENT_DIR/.env.example"
    if [ ! -f "$ENV_PATH" ]; then
        if [ -f "$ENV_EXAMPLE_PATH" ]; then
            cp "$ENV_EXAMPLE_PATH" "$ENV_PATH"
            print_success "Created .env from .env.example"
        else
            print_warning ".env file not found and no .env.example available"
            print_status "You'll need to create .env manually"
            return
        fi
    else
        print_success ".env file already exists"
    fi
    # Backup original .env
    cp "$ENV_PATH" "$ENV_PATH.backup"
    # Update database configuration
    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" "$ENV_PATH"
    sed -i "s/DB_HOST=.*/DB_HOST=mysql/" "$ENV_PATH"
    sed -i "s/DB_PORT=.*/DB_PORT=3306/" "$ENV_PATH"
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" "$ENV_PATH"
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=root/" "$ENV_PATH"
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" "$ENV_PATH"
    print_success ".env updated for Docker (backup saved as .env.backup)"
}

# Function to update docker-compose.yml
update_docker_compose() {
    print_status "Mengupdate docker-compose.yml sesuai input user..."
    DC_PATH="$SCRIPT_DIR/docker-compose.yml"
    if [ ! -f "$DC_PATH" ]; then
        print_error "docker-compose.yml not found!"
        exit 1
    fi
    # Backup
    cp "$DC_PATH" "$DC_PATH.backup"
    # Update MYSQL_DATABASE and MYSQL_ROOT_PASSWORD
    sed -i "s/MYSQL_DATABASE:.*/MYSQL_DATABASE: $DB_NAME/" "$DC_PATH"
    sed -i "s/MYSQL_ROOT_PASSWORD:.*/MYSQL_ROOT_PASSWORD: $DB_PASS/" "$DC_PATH"
    print_success "docker-compose.yml updated (backup saved as docker-compose.yml.backup)"
}

# Function to build and start containers
start_containers() {
    print_status "Building and starting Docker containers..."
    DC_PATH="$SCRIPT_DIR/docker-compose.yml"
    if [ ! -f "$DC_PATH" ]; then
        print_error "docker-compose.yml not found!"
        print_error "Make sure you're in the correct directory with Docker configuration"
        exit 1
    fi
    docker-compose -f "$DC_PATH" up -d --build
    print_success "Docker containers started successfully!"
    print_status "Waiting for services to be ready..."
    sleep 10
}

# Function to install Laravel dependencies
install_dependencies() {
    print_status "Installing Laravel dependencies..."
    # Check if vendor directory exists di parent Laravel
    if [ ! -d "$PARENT_DIR/vendor" ]; then
        print_status "Running composer install..."
        docker-compose -f "$SCRIPT_DIR/docker-compose.yml" exec laravel-app composer install
        print_success "Dependencies installed successfully!"
    else
        print_success "Dependencies already installed"
    fi
}

# Function to run Laravel setup
laravel_setup() {
    print_status "Setting up Laravel..."
    ENV_PATH="$PARENT_DIR/.env"
    # Generate application key if not exists
    if ! grep -q "APP_KEY=base64:" "$ENV_PATH"; then
        print_status "Generating application key..."
        docker-compose -f "$SCRIPT_DIR/docker-compose.yml" exec laravel-app php artisan key:generate
        print_success "Application key generated!"
    else
        print_success "Application key already exists"
    fi
    # Run migrations
    print_status "Running database migrations..."
    docker-compose -f "$SCRIPT_DIR/docker-compose.yml" exec laravel-app php artisan migrate --force
    print_success "Database migrations completed!"
}

# Function to show final information
show_info() {
    print_success "Setup completed successfully!"
    echo
    echo -e "${GREEN}=== Docker Laravel Setup Complete ===${NC}"
    echo -e "${BLUE}Application URL:${NC} http://localhost"
    echo -e "${BLUE}Database:${NC} MySQL on port 3306 (internal)"
    echo
    echo -e "${YELLOW}Useful commands:${NC}"
    echo "  docker-compose ps          # Check container status"
    echo "  docker-compose logs        # View logs"
    echo "  docker-compose down        # Stop containers"
    echo "  docker exec -it laravel-apache bash  # Enter container"
    echo
    echo -e "${GREEN}Happy coding! 🚀${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}=== Docker Laravel Setup Script ===${NC}"
    echo -e "${BLUE}Starting automated setup...${NC}"
    echo
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root. Some commands may behave differently."
    fi
    # Execute setup steps
    check_docker
    get_db_config
    configure_env
    update_docker_compose
    start_containers
    install_dependencies
    laravel_setup
    show_info
}

# Run main function
main "$@"