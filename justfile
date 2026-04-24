# Like GNU `make`, but `just` rustier.
# https://just.systems/
# run `just` from this directory to see available commands

# Default command when 'just' is run without arguments
default:
  @just --list

# Update nix flake
[group('Main')]
update:
  nix flake update

# Commit flake.lock after update
[group('Main')]
commit-flake-lock:
  git add flake.lock
  git commit -m 'Update `flake.lock`'

# Clean up old nix store paths and GC roots
[group('Main')]
clean:
  sudo nix-collect-garbage -d

# Update nix flake and commit flake.lock
[group('Main')]
update-and-commit:
  just update
  just commit-flake-lock

# Lint nix files
[group('dev')]
lint:
  nix fmt

# Check nix flake
[group('dev')]
check:
  nix flake check

# Manually enter dev shell
[group('dev')]
dev:
  nix develop

# Activate the configuration
[group('Main')]
run:
  nix run .#activate
