#!/bin/bash

# Parses a semantic version number and separates it into core version and metadata components
# Globals:
#   None
# Arguments:
#   semver: A string representing the semantic version
# Outputs:
#   Writes the major, minor, and patch version numbers to stdout, and outputs any pre-release or build metadata
parse_version() {
  local semver="$1"
  # Remove leading 'v' and isolate core version from pre-release/build metadata
  local core_version="${semver#v}"
  local metadata="${core_version#*[-+]}"
  core_version="${core_version%%[-+]*}"
  # Split the core version into parts
  IFS='.' read -r -a version_parts <<< "${core_version}"
  # Prepare metadata for output, ensuring it includes the preceding hyphen if present
  if [[ "$core_version" == "$metadata" ]]; then
    metadata=""
  else
    metadata="-${metadata}"
  fi
  echo "${version_parts[*]}" "$metadata"
}

# Bumps the version based on differences between two versions and appends any pre-release identifier from the new version
# Globals:
#   None
# Arguments:
#   old_semver: The old semantic version string
#   new_semver: The new semantic version string, potentially including pre-release identifiers
#   change_semver: The version string to be bumped
# Outputs:
#   Writes the bumped version to stdout, including any pre-release or build metadata from new_semver
bump_version() {
  local old_semver="$1"
  local new_semver="$2"
  local change_semver="$3"
  # Parse the versions to separate core version numbers and metadata
  read -r -a old_parts <<< "$(parse_version "${old_semver}")"
  read -r -a new_parts <<< "$(parse_version "${new_semver}")"
  read -r -a change_parts <<< "$(parse_version "${change_semver}")"
  local major=${change_parts[0]}
  local minor=${change_parts[1]}
  local patch=${change_parts[2]}
  local metadata=${new_parts[3]}

  # Compare version parts to determine which component to bump
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

  # Output the bumped version, appending new_version's pre-release identifier, if any
  echo "${major}.${minor}.${patch}${metadata}"
}

# Main function orchestrating the version bumping process
# Globals:
#   None
# Arguments:
#   old_semver: A string representing the old version
#   new_semver: A string representing the new version, which may include pre-release identifiers
#   change_semver: The version string that will be bumped
# Outputs:
#   Writes the bumped version, reflecting the highest order of change and any new pre-release identifier
main() {
  if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <old_semver> <new_semver> <version_to_change>" >&2
    exit 1
  fi

  local old_semver="$1"
  local new_semver="$2"
  local version_to_change="$3"

  local bumped_semver
  bumped_semver=$(bump_version "${old_semver}" "${new_semver}" "${version_to_change}")
  echo "${bumped_semver}"
}

# Call the main function and pass all the script arguments to it.
main "$@"
