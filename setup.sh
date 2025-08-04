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

# Function to setup project files
setup_project() {
    print_status "Setting up project files in current directory..."
    
    # Get the directory where the script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PARENT_DIR="$(dirname "$SCRIPT_DIR")"
    
    # Move all files from docker-experiment to parent directory
    if [ -d "$SCRIPT_DIR" ] && [ "$(basename "$SCRIPT_DIR")" = "docker-experiment" ]; then
        print_status "Moving files to parent directory..."
        
        # Move all visible files
        find "$SCRIPT_DIR" -maxdepth 1 -type f -exec mv {} "$PARENT_DIR/" \;
        
        # Move all hidden files (except . and ..)
        find "$SCRIPT_DIR" -maxdepth 1 -name ".*" -not -name "." -not -name ".." -exec mv {} "$PARENT_DIR/" \; 2>/dev/null || true
        
        # Move subdirectories
        find "$SCRIPT_DIR" -maxdepth 1 -type d -not -name "." -not -name ".." -exec mv {} "$PARENT_DIR/" \; 2>/dev/null || true
        
        # Change to parent directory
        cd "$PARENT_DIR"
        
        # Remove empty docker-experiment directory
        rmdir "$SCRIPT_DIR" 2>/dev/null || print_warning "Could not remove docker-experiment directory (not empty)"
        
        print_success "Files moved successfully!"
    else
        print_warning "Not in docker-experiment directory or directory structure unexpected"
    fi
}

# Function to configure environment
configure_env() {
    print_status "Configuring environment..."
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "Created .env from .env.example"
        else
            print_warning ".env file not found and no .env.example available"
            print_status "You'll need to create .env manually"
            return
        fi
    else
        print_success ".env file already exists"
    fi
    
    # Check if .env has proper database configuration
    if grep -q "DB_HOST=mysql" .env && grep -q "DB_CONNECTION=mysql" .env; then
        print_success ".env already configured for Docker"
    else
        print_status "Updating .env for Docker configuration..."
        
        # Backup original .env
        cp .env .env.backup
        
        # Update database configuration
        sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env
        sed -i 's/DB_HOST=.*/DB_HOST=mysql/' .env
        sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env
        sed -i 's/DB_DATABASE=.*/DB_DATABASE=laravel/' .env
        sed -i 's/DB_USERNAME=.*/DB_USERNAME=root/' .env
        sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=root/' .env
        
        print_success ".env updated for Docker (backup saved as .env.backup)"
    fi
}

# Function to build and start containers
start_containers() {
    print_status "Building and starting Docker containers..."
    
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found!"
        print_error "Make sure you're in the correct directory with Docker configuration"
        exit 1
    fi
    
    # Build and start containers
    docker-compose up -d --build
    
    print_success "Docker containers started successfully!"
    print_status "Waiting for services to be ready..."
    sleep 10
}

# Function to install Laravel dependencies
install_dependencies() {
    print_status "Installing Laravel dependencies..."
    
    # Check if vendor directory exists
    if [ ! -d "vendor" ]; then
        print_status "Running composer install..."
        docker-compose exec laravel-app composer install
        print_success "Dependencies installed successfully!"
    else
        print_success "Dependencies already installed"
    fi
}

# Function to run Laravel setup
laravel_setup() {
    print_status "Setting up Laravel..."
    
    # Generate application key if not exists
    if ! grep -q "APP_KEY=base64:" .env; then
        print_status "Generating application key..."
        docker-compose exec laravel-app php artisan key:generate
        print_success "Application key generated!"
    else
        print_success "Application key already exists"
    fi
    
    # Run migrations
    print_status "Running database migrations..."
    docker-compose exec laravel-app php artisan migrate --force
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
    setup_project
    configure_env
    start_containers
    install_dependencies
    laravel_setup
    show_info
}

# Run main function
main "$@"