#!/bin/bash
SCRIPTS_DIR=$(cd -- "$(dirname -- "$(readlink "$0" || echo "$0")")" && pwd)
GIT_COMMIT="${GIT_COMMIT:-0}" # identifier to commit version updates

function find_chart_updates() {
  local previous_tag="$1"
  local current_tag="$2"
  local glob_pattern="$3"
  local break_on_find="$4"
  local charts=""

  for pattern in $glob_pattern; do
    chart=$(git diff "${previous_tag}".."${current_tag}" --name-only -- "$pattern")

    if [ -n "$chart" ]; then
      charts="$charts $pattern"

      if [ -n "$break_on_find" ]; then
        break
      fi
    fi
  done

  echo "$charts"
}

update_helm_chart() {
  local previous_version="$1"
  local new_version="$2"
  local chart="$3"

  cd "$chart" || exit 3

  # Extract the current version from the Chart.yaml
  chart_version=$(grep '^version:' 'Chart.yaml' | awk '{print $2}')

  new_version=$("${SCRIPTS_DIR}/bump_version.sh" "$previous_version" "$new_version" "$chart_version")
  sed -i -E "s/^version: [0-9.]+/version: ${new_version}/" Chart.yaml

  echo "${new_version}"

  cd - > /dev/null || exit 4
}

update_helm_charts() {
  local previous_version="$1"
  local new_version="$2"
  local charts="$3"

  for chart in $charts; do
    echo "Update $chart"

    update_helm_chart "$previous_version" "$new_version" "$chart"

    note="Bump chart '$chart' from version '$chart_version' to '$new_version'"

    echo "$note"

    if [[ "$GIT_COMMIT" == "1" ]]; then
      echo git add './Chart.yaml'
      echo git commit -m "$note"
    fi

    cd - > /dev/null || exit 4
  done
}

note_base_chart_update() {
  local previous_version="$1"
  local new_version="$2"
  local chart="$3"

  note="Bump base chart from version to '$new_version'"

  echo "$note"

  if [[ "$GIT_COMMIT" == "1" ]]; then
    echo git add './Chart.yaml'
    echo git commit -m "$note"
  fi
}

update_helm_dependencies() {
  local base_chart_version="$1"
  local charts="$2"

  for chart in $charts; do
    echo "update $chart dependency to $1"
    cd "$chart" || exit 5

    sed -i '/- name: '"'"'media-servarr-base'"'"'/!b;n;s/version: .*/version: 0.2.100/' 'Chart.yaml'

    cd - || exit 6
  done
}

main() {
  # Fetch all tags
  git fetch --tags

  # Change directory to git repo root
  cd "$(git rev-parse --show-toplevel)" || exit 1

  # Get current and previous tag
  # previous_tag=$(git describe --tags --abbrev=0 "${current_tag}"^)
  # current_tag="${GITHUB_REF#refs/tags/}"
  previous_tag="main^^"
  current_tag="main^^^"
  previous_tag="main^^"
  current_tag=""

  all=$(find_chart_updates \
    "$previous_tag" \
    "$current_tag" \
    "templates/ .helmignore Chart.yaml values.yaml" \
    "1")

  if [ -n "$all" ]; then
    echo 'Base dependency changed. Updating all charts'

    previous_tag="0.0.0"
    current_tag="1.0.0"
    # update_helm_base_chart "$previous_tag" "$current_tag" "."
    new_version=$(update_helm_chart "$previous_tag" "$current_tag" ".")
    note_base_chart_update "$new_version"

    charts=$(find "./charts" -mindepth 1 -maxdepth 1 -print)

    update_helm_dependencies "$new_version" "${charts}"

    # update_helm_charts "${charts}"

    return
  fi

  charts=$(find_chart_updates \
    "$previous_tag" \
    "$current_tag" \
    "./charts/*")

  previous_tag="0.0.0"
  current_tag="1.0.0"
  update_helm_charts "$previous_tag" "$current_tag" "$charts"
}

main

exit 1

