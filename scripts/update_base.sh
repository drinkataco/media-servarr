#!/bin/bash

# This script automates the process of incrementing version numbers in Helm Chart.yaml files and updating specific dependencies.
# It supports major, minor, or patch version increments and updates dependencies to match the root Chart.yaml version.
# Usage: ./script.sh <major|minor|patch>
# Requirements: Bash 4.4 or later, yq tool for YAML processing.

set -e

# Check for yq command and exit if not found
if ! command -v yq &> /dev/null; then
    echo "yq could not be found. Please install yq to continue."
    exit 1
fi

# Increment version numbers based on the specified type (major, minor, patch).
# Arguments:
#   version: The current version string (e.g., "1.0.0").
#   type: The type of version increment (major, minor, patch).
# Outputs:
#   Prints the new version string to stdout.
increment_version() {
  local version=$1 type=$2
  local major minor patch IFS=.
  read -r major minor patch <<< "$version"

  case "$type" in
    major)
      ((major++)); minor=0; patch=0 ;;
    minor)
      ((minor++)); patch=0 ;;
    patch)
      ((patch++)) ;;
    *)
      echo "Invalid version type: $type" >&2; exit 1 ;;
  esac

  echo "${major}.${minor}.${patch}"
}

# Update the version in a Chart.yaml file.
# Arguments:
#   file: Path to the Chart.yaml file to update.
#   new_version: The new version string to apply.
# Outputs:
#   Writes changes to the specified file and logs the action.
update_chart_version() {
  local file=$1 new_version=$2
  echo "Updating version in $file to $new_version"
  sed -i "s/^version:.*/version: ${new_version}/" "$file"
}

# Update a specific dependency version in a Chart.yaml file.
# Arguments:
#   file: Path to the Chart.yaml file to update.
#   dependency_name: The name of the dependency to update (e.g., "base", "media-servarr-base").
#   new_version: The new version string for the dependency.
# Outputs:
#   Writes changes to the specified file and logs the action.
update_dependency_version() {
  local file=$1 dependency_name=$2 new_version=$3
  echo "Updating $dependency_name dependency version in $file to $new_version"
  yq eval -i ".dependencies[] |= (select(.name == \"$dependency_name\").version |= \"${new_version}\")" "$file"
}

# The main function orchestrates the version update process.
# It validates the input, updates the root Chart.yaml version, and then updates versions and dependencies in sub-chart Chart.yaml files.
# Arguments:
#   type: The type of version increment (major, minor, patch).
# Outputs:
#   Writes changes to Chart.yaml files and logs actions to stdout.
main() {
  local type=$1
  local current_version
  local new_version

  if [[ -z "$type" ]]; then
    echo "Usage: $0 <major|minor|patch>"
    exit 1
  fi

  local root_chart="./Chart.yaml"
  if [[ ! -f "$root_chart" ]]; then
    echo "Base Chart.yaml not found."
    exit 1
  fi

  current_version=$(yq eval '.version' "$root_chart")
  new_version=$(increment_version "$current_version" "$type")

  update_chart_version "$root_chart" "$new_version"

  echo "Base Chart.yaml updated from $current_version to $new_version"

  find charts -type f -name Chart.yaml | while read -r chart; do
    local sub_current_version
    local sub_new_version

    sub_current_version=$(yq eval '.version' "$chart")
    sub_new_version=$(increment_version "$sub_current_version" "$type")

    update_chart_version "$chart" "$sub_new_version"
    update_dependency_version "$chart" "base" "$new_version"
    update_dependency_version "$chart" "media-servarr-base" "$new_version"

    echo "$chart updated: version to $sub_new_version, base and media-servarr-base dependencies to $new_version"
  done

  echo "Version and dependencies updates completed."
}

main "$@"
