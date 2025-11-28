#!/bin/bash

# --- VARIABLES ---
DOCKER_PACKAGE="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
DOCKER_REPO="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# --- FUNCTIONS ---

# Function to check for and handle errors
check_error() {
  if [ $? -ne 0 ]; then
    echo "🚨 ERROR: $1" >&2
    exit 1
  fi
}

# Function to add user to the docker group
add_user_to_docker_group() {
  echo "--- Adding current user ($USER) to the 'docker' group ---"
  # Check if the docker group exists before trying to add the user
  if ! getent group docker > /dev/null; then
    sudo groupadd docker
    check_error "Failed to create the 'docker' group."
  fi

  sudo usermod -aG docker $USER
  check_error "Failed to add user to the 'docker' group."

  echo "✅ User $USER successfully added to the 'docker' group."
  echo "NOTE: You must **log out and log back in** for the group change to take effect!"
}

# Function to verify the installation
verify_installation() {
  echo "--- Verifying Docker Installation ---"
  # This runs the standard Docker "hello-world" container
  if docker run hello-world; then
    echo "✅ Docker is running correctly and installation is complete!"
  else
    echo "⚠️ Docker installation appears to have issues or the daemon isn't fully ready."
    echo "   Try running 'sudo systemctl status docker' to check the service status."
    exit 1
  fi
}

# --- MAIN INSTALLATION STEPS ---

echo "--- Starting Docker Engine Installation on Ubuntu ---"

# 1. Update package lists
echo "--- Updating package lists ---"
sudo apt-get update
check_error "Failed to update package lists."

# 2. Install necessary prerequisites
echo "--- Installing necessary prerequisites ---"
sudo apt-get install -y ca-certificates curl gnupg
check_error "Failed to install prerequisites."

# 3. Add Docker's official GPG key
echo "--- Adding Docker's official GPG key ---"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.asc
check_error "Failed to download and save GPG key."

# 4. Set repository permissions and add to Apt sources
echo "--- Setting repository permissions and adding to Apt sources ---"
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo $DOCKER_REPO | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
check_error "Failed to set up Docker repository."

# 5. Update package list again (to include Docker repository)
echo "--- Updating package lists with Docker repository ---"
sudo apt-get update
check_error "Failed to update package lists after adding Docker repo."

# 6. Install Docker packages
echo "--- Installing Docker packages: $DOCKER_PACKAGE ---"
sudo apt-get install -y $DOCKER_PACKAGE
check_error "Failed to install Docker packages."

# 7. Start/Enable the Docker service (though it usually starts automatically)
echo "--- Ensuring Docker service is running and enabled ---"
sudo systemctl enable docker
sudo systemctl start docker

# 8. Post-installation steps
add_user_to_docker_group

# 9. Verification
verify_installation

echo "--- INSTALLATION COMPLETE ---"

newgrp docker
