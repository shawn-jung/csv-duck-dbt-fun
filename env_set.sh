# Usage: `source envset.sh` (must be sourced, not executed, so exports persist).

# Absolute path of this script's directory, regardless of the caller's cwd.
# BASH_SOURCE[0] gives the sourced file's path in bash; falls back to $0 for sh/zsh.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" && pwd )"

# Tells dbt where to find profiles.yml — pinned to the repo's .dbt/ dir.
export DBT_PROFILES_DIR="$SCRIPT_DIR/.dbt"
