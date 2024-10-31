#!/bin/bash

# Define the shell profiles to check
PROFILES=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile")

# Docker Compose alias
ALIAS_DEFINITION="alias docker-compose='docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v \"\$(pwd)\":/workspace -w /workspace docker/compose:latest'"

# Function to add alias to profile
add_alias_to_profile() {
    local profile=$1
    
    # Check if alias already exists in the profile
    if grep -q "alias docker-compose=" "$profile"; then
        source "$profile"
        cd $HOME/app && docker-compose down && docker-compose up -d
        echo "Docker Compose alias already exists in $profile"
        return 0
    fi
    
    # Add alias to profile
    echo "" >> "$profile"
    echo "# Docker Compose alias" >> "$profile"
    echo "$ALIAS_DEFINITION" >> "$profile"
    echo "Added Docker Compose alias to $profile"
}

# Main script
echo "Setting up Docker Compose alias..."

# Find and update the appropriate profile
for profile in "${PROFILES[@]}"; do
    if [ -f "$profile" ]; then
        add_alias_to_profile "$profile"
        
        # Source the profile
        echo "Reloading $profile..."
        source "$profile"
        
        echo "Setup complete! You can now use 'docker-compose' commands."
        echo "Try running 'docker-compose --version' to test the alias."
        exit 0
    fi
done

echo "Error: No suitable profile found (.bashrc, .zshrc, or .bash_profile)"
exit 1