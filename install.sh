#!/bin/bash

# Create directories
sudo mkdir -p /usr/local/bin/todoodoo
sudo mkdir -p /usr/local/share/icons/todoodoo

# Copy application files
sudo cp -r build/linux/x64/release/bundle/* /usr/local/bin/todoodoo/

# Create symlink
sudo ln -sf /usr/local/bin/todoodoo/todoodoo /usr/local/bin/todoodoo

# Copy desktop entry
sudo cp todoodoo.desktop /usr/share/applications/

# Copy icon
sudo cp build/linux/x64/release/bundle/data/flutter_assets/assets/icon/icon.png /usr/local/share/icons/todoodoo/

# Set permissions
sudo chmod +x /usr/local/bin/todoodoo/todoodoo
sudo chmod +x /usr/local/bin/todoodoo

echo "ToDoodoo has been installed successfully!"
