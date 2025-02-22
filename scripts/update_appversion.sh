#!/bin/bash

set -ex

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
REPO_DIR="$(dirname "$script_dir")"

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

update_appversion() {
  local chart_file="$1"
  local latest_version="$2"

  sed -i "s/^appVersion: .*/appVersion: ${latest_version}/" "$chart_file"

  echo "Updated '${chart_file}' appVersion to '${latest_version}'"
}

update_chartversion() {
  local chart_file="$1"
  local appversion_old
  local appversion_new
  local chart_version

  # Start by identifying what type of update the appVersion was
  appversion_old=$(echo "$2" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
  appversion_new=$(echo "$3" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')

  IFS='.' read -r major_old minor_old patch_old <<< "$appversion_old"
  IFS='.' read -r major_new minor_new patch_new <<< "$appversion_new"

  # Now let's update the chart_version with the same type of upgrade
  chart_version=$(grep -E '^version:' "$chart_file" | sed -E 's/version: *//')
  IFS='.' read -r chart_major chart_minor chart_patch <<< "$chart_version"

  if [[ "$major_new" -gt "$major_old" ]]; then
    ((chart_major++))
    chart_minor=0
    chart_patch=0
  elif [[ "$minor_new" -gt "$minor_old" ]]; then
    ((chart_minor++))
    chart_patch=0
  elif [[ "$patch_new" -gt "$patch_old" ]]; then
    ((chart_patch++))
  else
    echo 'No update in version numbers found. How did you get here?' >&2
    exit 3
  fi

  new_chart_version="${chart_major}.${chart_minor}.${chart_patch}"

  echo "Updating Chart Version from '${chart_version}' to '${new_chart_version}'"

  sed -i "s/^version: .*/version: ${new_chart_version}/" "$chart_file"
}

main() {
  local name="$1"
  local repo="$2"
  local allow_prerelease="${3:-false}"
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
