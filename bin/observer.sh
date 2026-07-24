#!/bin/bash
# ==============================================================================
# All-Seeing DevOps Observer v2.0 — Multi-Project, Multi-Language
# ==============================================================================
# Monitors registered projects for failures across multiple languages.
# Queries the Neural Memory Engine before dispatching remediation.
# Supports: Bash, Python, JSON. Extensible to any linter.
# ==============================================================================

set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$WORKSPACE_DIR/observer.log"
REMEDIATE_SCRIPT="$WORKSPACE_DIR/bin/remediate.sh"
MEMORY_ENGINE="$WORKSPACE_DIR/bin/memory-engine.sh"
CONFIG_FILE="$WORKSPACE_DIR/projects.conf"
MAX_RETRIES=3
RETRY_COUNT_FILE="/tmp/agentic-retry-count"

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1" | tee -a "$LOG_FILE"
}

# ── Load registered projects ─────────────────────────────────────────────────
load_projects() {
    local projects=()
    projects+=("$WORKSPACE_DIR")
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" || "$line" == \#* ]] && continue
            [[ -d "$line" ]] && projects+=("$line")
        done < "$CONFIG_FILE"
    fi
    echo "${projects[@]}"
}

# ── Check retry budget (prevents infinite API bill loops) ─────────────────────
check_retry_budget() {
    local file_hash
    file_hash=$(echo "$1" | md5sum | cut -d' ' -f1 2>/dev/null || echo "$1")
    local count_file="${RETRY_COUNT_FILE}-${file_hash}"
    local count=0
    [[ -f "$count_file" ]] && count=$(cat "$count_file")
    if [[ $count -ge $MAX_RETRIES ]]; then
        log "🛑 Max retries ($MAX_RETRIES) reached for $1. Skipping."
        return 1
    fi
    echo $((count + 1)) > "$count_file"
    return 0
}

# ── Language-specific health checks ──────────────────────────────────────────
check_bash() {
    local project_dir="$1"
    for script in "$project_dir"/bin/*.sh "$project_dir"/*.sh; do
        [[ -f "$script" ]] || continue
        if ! bash -n "$script" 2>/tmp/lint_error.log; then
            echo "$script|$(cat /tmp/lint_error.log)"
            return
        fi
    done
}

check_python() {
    local project_dir="$1"
    for pyfile in "$project_dir"/*.py "$project_dir"/src/*.py; do
        [[ -f "$pyfile" ]] || continue
        if ! python3 -m py_compile "$pyfile" 2>/tmp/lint_error.log; then
            echo "$pyfile|$(cat /tmp/lint_error.log)"
            return
        fi
    done
}

check_json() {
    local project_dir="$1"
    for jsonfile in "$project_dir"/*.json; do
        [[ -f "$jsonfile" ]] || continue
        [[ "$(basename "$jsonfile")" == "package-lock.json" ]] && continue
        if ! python3 -c "import json; json.load(open('$jsonfile'))" 2>/tmp/lint_error.log; then
            echo "$jsonfile|$(cat /tmp/lint_error.log)"
            return
        fi
    done
}

# ── Main health check ────────────────────────────────────────────────────────
check_health() {
    local projects
    projects=$(load_projects)

    for project_dir in $projects; do
        log "👁️ Scanning: $project_dir"

        local failure=""

        failure=$(check_bash "$project_dir" 2>/dev/null || true)
        [[ -z "$failure" ]] && failure=$(check_python "$project_dir" 2>/dev/null || true)
        [[ -z "$failure" ]] && failure=$(check_json "$project_dir" 2>/dev/null || true)

        if [[ -n "$failure" ]]; then
            local file_path error_msg
            file_path=$(echo "$failure" | cut -d'|' -f1)
            error_msg=$(echo "$failure" | cut -d'|' -f2-)

            log "⚠️ Anomaly detected in $file_path"

            # Query Neural Memory for past solutions
            local memory_context=""
            if [[ -f "$MEMORY_ENGINE" ]]; then
                memory_context=$(bash "$MEMORY_ENGINE" recall "$error_msg" 2>/dev/null || true)
                [[ -n "$memory_context" ]] && log "🧠 Found related past fixes in memory"
            fi

            # Check retry budget before dispatching
            if check_retry_budget "$file_path"; then
                log "🚀 Dispatching remediation..."
                bash "$REMEDIATE_SCRIPT" "$file_path" "$error_msg" "$memory_context" || true
            fi
            return
        fi
    done

    log "✅ All projects healthy."
}

# ── Entrypoint ────────────────────────────────────────────────────────────────
case "${1:-once}" in
    --start)
        log "🚀 Starting Autonomous Observer v2.0 (multi-project, multi-language)..."
        while true; do
            check_health
            sleep 60
        done
        ;;
    --status)
        echo "📊 Observer Status"
        echo "   Log: $LOG_FILE"
        echo "   Projects: $(load_projects | wc -w)"
        [[ -f "$MEMORY_ENGINE" ]] && bash "$MEMORY_ENGINE" stats
        ;;
    *)
        check_health
        ;;
esac
