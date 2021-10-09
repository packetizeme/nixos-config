#!/bin/sh
# Create files required to use our configs
# TODO This is a crappy solution. Can we do this in Nix, adjacent to anything that requires this bootstrapping?

# Create directory to store SSH host keys
mkdir -p /persist/secrets/ssh

# Create initrd ssh host keys -- required for remote unlock. Unlike system SSH, we need to generate these ourselves.
mkdir -p /persist/secrets/initrd
ssh-keygen -t ed25519 -N "" -f /persist/secrets/initrd/ssh_host_ed25519_key
