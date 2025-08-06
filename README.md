# Dotfiles

This is my personal dotfiles setup. It includes configurations for `zsh`, `tmux`, `git`, and more, along with a script to automate the setup process.

## Installation

To install these dotfiles, clone the repository and run the setup script:

```bash
git clone <your-repo-url> ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

The `setup.sh` script will automatically:
- Install dependencies using Homebrew (macOS) or APT (Debian/Ubuntu).
- Install Oh My Zsh and custom plugins.
- Create symlinks for the configuration files in your home directory.

## Testing

This project includes a fully automated testing environment using Docker to ensure that the setup script works correctly in a clean environment.

To run the tests, make sure you have Docker installed and then execute the `test.sh` script:

```bash
./test.sh
```

This script will:
1.  Build a Docker image from a clean Ubuntu base.
2.  Run the `setup.sh` script inside the container.
3.  Execute the `verify.sh` script to check that all dependencies are installed and all symlinks are created correctly.

If the script completes without errors, the setup is verified.

### Manual Inspection

To manually inspect the container environment after the setup has run, you can build the image and then run an interactive shell:

```bash
# Build the image first
docker build -t dotfiles-test .

# Run a container with an interactive zsh shell
docker run --rm -it dotfiles-test /bin/zsh
```