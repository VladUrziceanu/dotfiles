#!/usr/bin/env bash
set -e -u -o pipefail

echo "--- Starting Dotfiles Test ---"

# 1. Build the Docker image
# The 'setup.sh' script is run during this phase.
# If the setup fails, the build will fail.
echo
echo "--- Building test container (runs setup.sh) ---"
docker build -t dotfiles-test .

# 2. Run the verification script
# The 'verify.sh' script is the default command for the container.
# If any check inside it fails, it will exit with a non-zero code,
# causing this script to fail as well.
echo
echo "--- Running verification script inside the container ---"
docker run --rm dotfiles-test

echo
echo "--- Test Complete: All checks passed! ---"
