#!/bin/bash

# Parses a version number into its components and returns them as space-separated string.
# Globals:
#   None
# Arguments:
#   Version string
# Outputs:
#   Writes the version components to stdout
parse_version() {
  local version="$1"
  IFS='.' read -r -a version_parts <<< "${version}"
  echo "${version_parts[*]}"
}

# Bumps the version based on the highest difference between two versions compared to a base version.
# Globals:
#   None
# Arguments:
#   Old version string
#   New version string
#   Version to change string
# Outputs:
#   Writes the bumped version to stdout
bump_version() {
  local -a old_parts=($(parse_version "$1"))
  local -a new_parts=($(parse_version "$2"))
  local -a change_parts=($(parse_version "$3"))
  local major=${change_parts[0]}
  local minor=${change_parts[1]}
  local patch=${change_parts[2]}

  # Determine which component to bump.
  if (( old_parts[0] != new_parts[0] )); then
    ((major++))
    minor=0
    patch=0
  elif (( old_parts[1] != new_parts[1] )); then
    ((minor++))
    patch=0
  elif (( old_parts[2] != new_parts[2] )); then
    ((patch++))
  fi

  echo "${major}.${minor}.${patch}"
}

# Main function to control the flow of the script.
# Globals:
#   None
# Arguments:
#   Old version string
#   New version string
#   Version to change string
# Outputs:
#   Writes the bumped version or an error message to stdout
main() {
  if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <old_version> <new_version> <version_to_change>" >&2
    exit 1
  fi

  local old_version="$1"
  local new_version="$2"
  local version_to_change="$3"

  local bumped_version
  bumped_version=$(bump_version "${old_version}" "${new_version}" "${version_to_change}")
  echo "Bumped version: ${bumped_version}"
}

# Call the main function and pass all the script arguments to it.
main "$@"
