# Use a standard Ubuntu image as the base
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install sudo, git, and other basic dependencies needed for the script itself
RUN apt-get update && apt-get install -y sudo git zsh curl wget

# Create a non-root user to run the setup script, as this is the typical use case.
# The user is named 'testuser' and is added to the sudo group.
RUN useradd --create-home --shell /bin/zsh testuser && \
    adduser testuser sudo && \
    echo "testuser:testuser" | chpasswd && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the non-root user
USER testuser
WORKDIR /home/testuser

# Copy all the dotfiles from the host into the container's home directory
# The .dockerignore file will prevent .git and other specified files from being copied.
COPY . .

# Make the setup and verification scripts executable
RUN sudo chown -R testuser:testuser . && \
    chmod +x setup.sh verify.sh

# --- The container will build up to this point ---
# Run the setup script as part of the image build.
# If it fails, the build will stop here.
RUN /bin/bash ./setup.sh

# The default command for the container is now to run the verification script.
CMD ["/bin/bash", "./verify.sh"]
