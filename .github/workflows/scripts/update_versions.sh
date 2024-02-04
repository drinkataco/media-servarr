#!/usr/bin/env bash
# Updates Helm chart versions and dependencies based on Git tag comparisons.
# This script utilizes environment variables and a set of defined functions to
# manage Helm chart versions within a Git repository, optionally committing changes.
set -e
set -o errexit # Exit on most errors
set -o pipefail # Catch errors in pipelines

# Global Variables:
#   SCRIPTS_DIR: Directory containing this script and possibly other utility scripts
#   GIT_COMMIT: Controls whether changes are committed to Git. (1 = commit, 0 = no commit)
#   COMMIT_PREFIX: Prefix for git commit messages
SCRIPTS_DIR=$(cd -- "$(dirname -- "$(readlink "$0" || echo "$0")")" && pwd)
GIT_COMMIT="${GIT_COMMIT:-0}"
COMMIT_PREFX="💫 "

# source shared functiontags
source "${SCRIPTS_DIR}/updated_charts.sh"

# Identifies chart updates between two Git tags
# Arguments:
#   previous_ref: Previous Git reference
#   current_tag: Current Git reference
#   glob_pattern: Glob pattern for chart files
#   break_on_find: Break on first find flag (any non-empty value causes break)
# Outputs:
#   Space-separated list of charts that have updates
find_chart_updates() {
  local previous_ref="$1"
  local current_ref="$2"
  local glob_pattern="$3"
  local break_on_find="$4"
  local charts_found=""

  for pattern in $glob_pattern; do
    local chart
    chart=$(git diff "${previous_ref}".."${current_ref}" --name-only -- "$pattern")
    if [[ -n "$chart" ]]; then
      charts_found="$charts_found $pattern"
      if [[ -n "$break_on_find" ]]; then
        break
      fi
    fi
  done

  echo "$charts_found"
}

# Updates the version of a Helm chart
# Arguments:
#   previous_version: Previous chart version
#   new_version: New chart version
#   chart_dir: Chart directory
# Outputs:
#   The new version of the chart.
update_helm_chart() {
  local previous_version="$1"
  local new_version="$2"
  local chart_dir="$3"
  local chart_version

  pushd "$chart_dir" > /dev/null || exit 3
  chart_version=$(grep '^version:' 'Chart.yaml' | awk '{print $2}')
  new_version=$("${SCRIPTS_DIR}/bump_version.sh" "$previous_version" "$new_version" "$chart_version")
  sed -i -E "s/^version: [0-9.]+/version: ${new_version}/" Chart.yaml
  popd > /dev/null || exit 4
}

# Iterates through a list of charts and updates their versions
# Globals:
#   COMMIT_PREFX
#   GIT_COMMIT
# Arguments:
#   previous_version: Previous version
#   new_version: New version
#   charts: Space-separated list of chart directories
update_helm_charts() {
  local previous_version="$1"
  local new_version="$2"
  local charts="$3"

  for chart in $charts; do
    echo "Updating $chart..."
    update_helm_chart "$previous_version" "$new_version" "$chart"
    local note="Bump chart '$chart' to '$new_version'"
    echo "$note"

    if [[ "$GIT_COMMIT" == "1" ]]; then
      git add "./$chart/Chart.yaml"
      git commit -m "${COMMIT_PREFX}${note}"
    fi
  done
}

# Updates the Helm chart dependencies to a new version
# Globals:
#   COMMIT_PREFX
#   GIT_COMMIT
# Arguments:
#   base_chart_version: Base chart version
#   charts: Space-separated list of chart directories
update_helm_dependencies() {
  local base_chart_version="$1"
  local charts="$2"

  for chart in $charts; do
    echo "Updating $chart dependency to $base_chart_version"
    pushd "$chart" > /dev/null || exit 5
    sed -i '/- name: '"'"'media-servarr-base'"'"'/!b;n;s/version: .*/version: '"$base_chart_version"'/' 'Chart.yaml'
    local note="Update base dependency of $chart to '$base_chart_version'"
    echo "$note"

    if [[ "$GIT_COMMIT" == "1" ]]; then
      git add './Chart.yaml'
      git commit -m "${COMMIT_PREFX}${note}"
    fi

    popd > /dev/null || exit 4
  done
}

# Main function orchestrating the version bumping process
# Globals:
#   COMMIT_PREFX
#   GIT_COMMIT
# Arguments:
#   previous_tag: Previous semvar formatted tag
#   previous_tag: Current semvar formatted tag
main() {
  local previous_tag="$1"
  local current_tag="$2"
  local update_all
  local charts

  echo "Update versions using comparison"
  echo "Current Tag Version: $current_tag"
  echo "Previous Tag Version: $previous_tag"

  # Change directory to git repo root
  cd "$(git rev-parse --show-toplevel)" || exit 1

  update_all=$(updated_charts \
    "$previous_tag" \
    "$current_tag" \
    "templates/ .helmignore Chart.yaml values.yaml" \
    "1")

  if [[ -n "$update_all" ]]; then
    echo 'Base dependency changed. Updating all charts.'

    # Update the base chart itself.
    new_version=$(update_helm_chart "$previous_tag" "$current_tag" ".")

    # Optionally note the base chart update in a commit message.
    local note="Bump base chart to '$new_version'"

    echo "$note"

    if [[ "$GIT_COMMIT" == "1" ]]; then
      git add './Chart.yaml'
      git commit -m "${COMMIT_PREFX}${note}"
    fi
    # Find and update helm dependencies in all charts.
    charts=$(find "./charts" -mindepth 1 -maxdepth 1 -print)
    update_helm_dependencies "$new_version" "$charts"
    update_helm_charts "$previous_version" "$current_tag" "$charts"

    exit
  fi

  # If no base dependency changes were found, update charts individually.
  charts=$(updated_charts "$previous_tag" "$current_tag" "./charts/*")
  update_helm_charts "$previous_version" "$new_version" "$charts"
}

main "$@"
