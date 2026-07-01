#!/bin/bash
set -e
# We need to install our script into wherever the metaphlan package is.
# Resolve that location dynamically from the active Python environment
# instead of hardcoding a path into a specific conda env.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METAPHLAN_UTILS_DIR=$(python3 -c "import os, metaphlan; print(os.path.join(os.path.dirname(metaphlan.__file__), 'utils'))")

cp "${SCRIPT_DIR}/sgb_to_gtdb_extra_cols.py" "${METAPHLAN_UTILS_DIR}/sgb_to_gtdb_extra_cols.py"
