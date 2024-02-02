#!/usr/bin/env bash
# Identifies chart updates between two Git references
# Arguments:
#   previous_ref: Previous Git reference
#   current_tag: Current Git reference
#   glob_pattern: Glob pattern for chart files - charts/* by default
#   break_on_find: Break on first find flag (any non-empty value causes break)
# Outputs:
#   Space-separated list of charts that have updates
function updated_charts() {
  local previous_ref="$1"
  local current_ref="$2"
  local glob_pattern="${3:-'charts/*'}"
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

export -f updated_charts
