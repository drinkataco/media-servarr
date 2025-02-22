#!/usr/bin/env bash
# shellcheck disable=SC2003 # disabled due to ((chart++)) bug with 0 values
#
# Updates a Helm chart's appVersion based on the latest release for a given GitHub repository,
# then increments the chart version accordingly

set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Fetches the latest version from GitHub releases for a given repository
# Arguments:
#   repo: The GitHub repository in the form "owner/repo".
#   allow_prerelease: A boolean string ("true" or "false") indicating whether to allow prerelease versions.
# Outputs:
#   Writes the latest version tag to stdout.
get_latest_version() {
  local repo="$1"
  local allow_prerelease="$2"
  local prerelease_filter=''

  # If we allow prereleases we will omitt this filter
  if [[ "$allow_prerelease" == "false" ]]; then
    prerelease_filter="map(select(.prerelease == false)) |"
  fi

  curl -s "https://api.github.com/repos/${repo}/releases" | \
    jq -r "${prerelease_filter} first | .tag_name"
}

# Reads the 'appVersion' field from the specified Chart.yaml file.
# Arguments:
#   chart_file: The path to the Chart.yaml file.
# Outputs:
#   Writes the current appVersion to stdout.
# Returns:
#   0 if successful, non-zero on error (2 if file not found, 1 if no appVersion).
get_current_app_version() {
  local chart_file="$1"
  local app_version

  # Check if the file exists
  if [[ ! -f "$chart_file" ]]; then
    echo "Error: $chart_file not found!" >&2
    exit 2
  fi

  app_version=$(awk '/^appVersion:/ {print $2}' "$chart_file")

  # Ensure we got a result
  if [[ -z "$app_version" ]]; then
    echo "Error: appVersion not found in $chart_file"
    exit 1
  fi

  # Output the appVersion
  echo "$app_version"
}

# Updates the 'appVersion' field in the specified Chart.yaml file to a new value.
# Arguments:
#   chart_file: The path to the Chart.yaml file.
#   latest_version: The latest version to set as appVersion.
update_appversion() {
  local chart_file="$1"
  local latest_version="$2"

  sed -i "s/^appVersion: .*/appVersion: ${latest_version}/" "$chart_file"

  echo "Updated '${chart_file}' appVersion to '${latest_version}'"
}

# Increments the Helm chart's 'version' based on the difference between old and new appVersion.
# Arguments:
#   chart_file: The path to the Chart.yaml file.
#   appversion_old: The old appVersion.
#   appversion_new: The new appVersion.
# Outputs:
#   Writes the new chart version to stdout.
update_chartversion() {
  local chart_file="$1"
  local appversion_old
  local appversion_new
  local chart_version

  # Start by identifying what type of update the appVersion was
  appversion_old=$(echo "$2" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  appversion_new=$(echo "$3" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

  IFS='.' read -r major_old minor_old patch_old <<< "$appversion_old"
  IFS='.' read -r major_new minor_new patch_new <<< "$appversion_new"

  # Now let's update the chart_version with the same type of upgrade
  chart_version=$(grep -E '^version:' "$chart_file" | sed -E 's/version: *//')
  IFS='.' read -r chart_major chart_minor chart_patch <<< "$chart_version"

  if [[ "$major_new" -gt "$major_old" ]]; then
    chart_major=$(expr "$chart_major" + 1)
    chart_minor=0
    chart_patch=0
  elif [[ "$minor_new" -gt "$minor_old" ]]; then
    chart_minor=$(expr "$chart_minor" + 1)
    chart_patch=0
  elif [[ "$patch_new" -gt "$patch_old" ]]; then
    chart_patch=$(expr "$chart_patch" + 1)
  else
    ## This could be a build update, so we'll assume patch also
    chart_patch=$(expr "$chart_patch" + 1)
  fi

  new_chart_version="${chart_major}.${chart_minor}.${chart_patch}"

  echo "Updating Chart Version from '${chart_version}' to '${new_chart_version}'"

  sed -i "s/^version: .*/version: ${new_chart_version}/" "$chart_file"
}

# Determines the latest release, checks the current appVersion, and updates both appVersion
# and Chart version if needed.
#
# Globals:
#   REPO_DIR: The base directory for the repository.
#   ALLOW_PRERELEASE: A boolean string ("true" or "false") indicating whether to allow prerelease versions (default: false).
# Arguments:
#   name: The name of the chart (folder under charts/).
#   repo: The GitHub repository in the form "owner/repo".
# Outputs:
#   Writes changes to Chart.yaml files and logs actions to stdout.
main() {
  local name="$1"
  local repo="$2"
  local allow_prerelease="${ALLOW_PRERELEASE:-false}"
  local chart_file="${REPO_DIR}/charts/${name}/Chart.yaml"
  local latest_version
  local current_version

  latest_version=$(get_latest_version "$repo" "$allow_prerelease")

  if [[ "${latest_version}" == 'null' ]]; then
    echo "No Release Found for ${repo}" >&2
    exit 1;
  fi

  echo "Release '${latest_version}' found for '${repo}'"

  current_version=$(get_current_app_version "${chart_file}")

  if [[ "${latest_version}" == "${current_version}" ]]; then
    echo 'Chart is already up to date'
    exit
  fi

  echo "Current chart uses appVersion ${current_version}"

  update_appversion "${chart_file}" "${latest_version}"

  update_chartversion "${chart_file}" "${current_version}" "${latest_version}"
}

main "$@"
