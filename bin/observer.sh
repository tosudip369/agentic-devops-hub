#!/bin/bash
# ==============================================================================
# All-Seeing DevOps Observer
# ==============================================================================

set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="observer.log"
REMEDIATE_SCRIPT="$WORKSPACE_DIR/bin/remediate.sh"

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1" | tee -a "$LOG_FILE"
}

check_health() {
    log "👁️ All-Seeing Eye: Scanning workspace health (bash syntax)..."
    
    for script in "$WORKSPACE_DIR"/bin/*.sh; do
        if ! bash -n "$script" 2>/tmp/bash_syntax_error.log; then
            local error_msg
            error_msg=$(cat /tmp/bash_syntax_error.log)
            log "⚠️ Anomaly detected! Syntax error in $script:"
            log "$error_msg"
            
            if [[ -f "$REMEDIATE_SCRIPT" ]]; then
                log "🚀 Triggering remediation for $script..."
                bash "$REMEDIATE_SCRIPT" "$script" "$error_msg"
            else
                log "❌ Remediation script not found at $REMEDIATE_SCRIPT"
            fi
            return
        fi
    done

    log "✅ Workspace is healthy. All systems nominal."
}

if [[ "${1:-}" == "--start" ]]; then
    log "Starting Autonomous DevOps Observer..."
    while true; do
        check_health
        sleep 60
    done
else
    check_health
fi
