#!/bin/sh
# ==============================================================================
# Brave Origin Profile Configuration Tool for macOS
#
# Inspired by: https://github.com/ObjectAscended/brave-origin-unlocker
# Native macOS implementation: 100% zero external dependencies (no Deno, Node,
# Python, or Homebrew required). Uses native macOS subsystem utilities:
#   - /bin/zsh & /bin/sh (POSIX compatibility)
#   - osascript (JavaScript for Automation / JXA) & plutil for atomic JSON mutation
#   - hdiutil, ditto, curl for native DMG mounting and application deployment
# ==============================================================================

set -e

# --- Terminal Styling ---
if [ -t 1 ]; then
    COLOR_RESET="\033[0m"
    COLOR_GREEN="\033[1;32m"
    COLOR_CYAN="\033[1;36m"
    COLOR_YELLOW="\033[1;33m"
    COLOR_RED="\033[1;31m"
    COLOR_BOLD="\033[1m"
else
    COLOR_RESET=""
    COLOR_GREEN=""
    COLOR_CYAN=""
    COLOR_YELLOW=""
    COLOR_RED=""
    COLOR_BOLD=""
fi

log_info() {
    printf "${COLOR_CYAN}[*]${COLOR_RESET} %s\n" "$1"
}

log_success() {
    printf "${COLOR_GREEN}[+]${COLOR_RESET} %s\n" "$1"
}

log_warn() {
    printf "${COLOR_YELLOW}[!]${COLOR_RESET} %s\n" "$1"
}

log_error() {
    printf "${COLOR_RED}[-]${COLOR_RESET} %s\n" "$1" >&2
}

# --- System & Environment Detection ---
detect_environment() {
    OS_NAME="$(uname -s 2>/dev/null || echo "Unknown")"
    if [ "$OS_NAME" != "Darwin" ]; then
        log_error "This script is designed specifically for macOS (Darwin). Detected OS: $OS_NAME"
        exit 1
    fi

    MACOS_VER="$(sw_vers -productVersion 2>/dev/null || echo "Unknown")"
    MACOS_BUILD="$(sw_vers -buildVersion 2>/dev/null || echo "Unknown")"
    ARCH="$(uname -m 2>/dev/null || echo "Unknown")"

    # Detect if running under Rosetta 2 emulation on Apple Silicon
    if [ "$ARCH" = "x86_64" ]; then
        IS_TRANSLATED="$(sysctl -in sysctl.proc_translated 2>/dev/null || echo 0)"
        if [ "$IS_TRANSLATED" = "1" ]; then
            ARCH="arm64"
        fi
    fi

    log_info "Detected macOS ${COLOR_BOLD}${MACOS_VER}${COLOR_RESET} (Build ${MACOS_BUILD}, Architecture: ${COLOR_BOLD}${ARCH}${COLOR_RESET})"
}

# --- Usage / Help ---
show_help() {
    cat <<EOF
Brave Origin Profile Configuration Tool for macOS
Zero-dependency native automation utility.

Usage:
  ./profile.sh [options]

Options:
  -c, --channel <channel>   Target channel: Release, Beta, Nightly, or All (default: All)
  -p, --path <path>         Custom path to User Data directory
  -i, --install             Download and install official Brave Origin DMG if not installed
  -f, --force               Automatically terminate running Brave processes without prompting
  -r, --restore             Restore previous 'Local State.bak' configuration backup
      --no-backup           Skip creating a configuration backup (.bak)
  -h, --help                Display this help message and exit

Examples:
  ./profile.sh
      Auto-detects installed Brave Origin channels and applies profile configuration.

  ./profile.sh -i -f
      Installs Brave Origin (if missing), closes active processes, and patches profile.

  ./profile.sh -c Beta
      Configures profile specifically for Brave Origin Beta.

  ./profile.sh -r
      Restores the original Local State configuration from backup.
EOF
}

# --- Default Configuration ---
CHANNEL="All"
CUSTOM_PATH=""
INSTALL_FLAG=0
FORCE_FLAG=0
RESTORE_FLAG=0
NO_BACKUP=0

# --- Parse Arguments ---
while [ $# -gt 0 ]; do
    case "$1" in
        -c|--channel)
            CHANNEL="$2"
            shift 2
            ;;
        -p|--path|--user-data-dir)
            CUSTOM_PATH="$2"
            shift 2
            ;;
        -i|--install)
            INSTALL_FLAG=1
            shift
            ;;
        -f|--force)
            FORCE_FLAG=1
            shift
            ;;
        -r|--restore)
            RESTORE_FLAG=1
            shift
            ;;
        --no-backup)
            NO_BACKUP=1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# --- Process Management ---
stop_running_brave() {
    PROCESS_NAMES="Brave Origin|Brave Origin Beta|Brave Origin Nightly"
    if pgrep -f "$PROCESS_NAMES" >/dev/null 2>&1; then
        if [ $FORCE_FLAG -eq 1 ]; then
            log_info "Closing running Brave Origin instances (--force active)..."
            pkill -f "$PROCESS_NAMES" >/dev/null 2>&1 || true
            sleep 1
            # Force kill if still lingering
            if pgrep -f "$PROCESS_NAMES" >/dev/null 2>&1; then
                pkill -9 -f "$PROCESS_NAMES" >/dev/null 2>&1 || true
                sleep 1
            fi
            log_success "All Brave Origin processes closed."
        else
            log_warn "Brave Origin is currently running. Modifications while running may be overwritten."
            printf "Would you like to close Brave Origin processes now? [Y/n]: "
            read -r response
            case "$response" in
                [nN][oO]|[nN])
                    log_warn "Continuing without closing Brave Origin. Changes may require restart."
                    ;;
                *)
                    pkill -f "$PROCESS_NAMES" >/dev/null 2>&1 || true
                    sleep 1
                    log_success "Brave Origin processes closed."
                    ;;
            esac
        fi
    fi
}

# --- Native DMG Downloader & Installer ---
install_brave_origin() {
    log_info "Initiating official Brave Origin installation for macOS ($ARCH)..."

    # Select architecture-specific direct CDN payload
    if [ "$ARCH" = "arm64" ]; then
        DOWNLOAD_URLS="https://referrals.brave.com/latest/Brave-Origin-arm64.dmg https://laptop-updates.brave.com/latest/origin/osxarm64/release"
    else
        DOWNLOAD_URLS="https://referrals.brave.com/latest/Brave-Origin.dmg https://laptop-updates.brave.com/latest/origin/osx/release"
    fi

    DMG_TMP="/tmp/Brave-Origin-${ARCH}.dmg"
    DOWNLOADED=0

    for url in $DOWNLOAD_URLS; do
        log_info "Downloading from: $url"
        if curl -fL --progress-bar -o "$DMG_TMP" "$url"; then
            if [ -f "$DMG_TMP" ] && [ "$(stat -f%z "$DMG_TMP" 2>/dev/null || stat -c%s "$DMG_TMP" 2>/dev/null || echo 0)" -gt 1000000 ]; then
                log_success "Download complete ($DMG_TMP)."
                DOWNLOADED=1
                break
            fi
        fi
        log_warn "Failed to download from $url, trying fallback..."
    done

    if [ $DOWNLOADED -eq 0 ]; then
        log_error "Failed to download Brave Origin installer. Please download manually from https://brave.com/origin"
        return 1
    fi

    # Mount DMG quietly using native hdiutil
    log_info "Mounting disk image via native hdiutil..."
    MOUNT_DIR=$(mktemp -d /tmp/brave_mount.XXXXXX)
    if ! hdiutil attach "$DMG_TMP" -nobrowse -readonly -mountpoint "$MOUNT_DIR" -quiet; then
        log_error "Failed to mount disk image: $DMG_TMP"
        rm -f "$DMG_TMP"
        rm -rf "$MOUNT_DIR"
        return 1
    fi

    # Locate the .app bundle inside the mounted volume
    APP_BUNDLE=$(find "$MOUNT_DIR" -maxdepth 1 -name "*.app" | head -n 1)
    if [ -z "$APP_BUNDLE" ]; then
        log_error "Could not find .app bundle inside disk image."
        hdiutil detach "$MOUNT_DIR" -quiet -force || true
        rm -f "$DMG_TMP"
        rm -rf "$MOUNT_DIR"
        return 1
    fi

    APP_NAME="$(basename "$APP_BUNDLE")"
    
    # Determine target destination directory
    TARGET_APPS="/Applications"
    if [ ! -w "$TARGET_APPS" ]; then
        TARGET_APPS="$HOME/Applications"
        mkdir -p "$TARGET_APPS"
    fi

    DEST_APP="$TARGET_APPS/$APP_NAME"
    log_info "Installing ${COLOR_BOLD}$APP_NAME${COLOR_RESET} to $TARGET_APPS..."

    # Use native ditto to copy while preserving permissions, resource forks, and codesigns
    ditto "$APP_BUNDLE" "$DEST_APP"

    # Remove quarantine attribute to satisfy Gatekeeper
    xattr -cr "$DEST_APP" 2>/dev/null || true

    # Clean up DMG mount and temporary files
    log_info "Cleaning up installer resources..."
    hdiutil detach "$MOUNT_DIR" -quiet -force || true
    rm -f "$DMG_TMP"
    rm -rf "$MOUNT_DIR"

    log_success "${COLOR_BOLD}$APP_NAME${COLOR_RESET} installed successfully to $DEST_APP!"
    return 0
}

# --- Safe Native JSON Patch Engine ---
# Evaluates and modifies the Chromium Local State file using native macOS engines:
# Priority 1: osascript (JavaScript for Automation - JXA) using Foundation classes.
# Priority 2: python3 (if pre-configured).
# Priority 3: plutil (Property List Utility, preinstalled on all macOS versions).
patch_local_state() {
    STATE_FILE="$1"
    CHANNEL_NAME="$2"

    STATE_DIR="$(dirname "$STATE_FILE")"
    if [ ! -d "$STATE_DIR" ]; then
        mkdir -p "$STATE_DIR"
    fi

    # Backup management
    if [ $NO_BACKUP -eq 0 ] && [ -f "$STATE_FILE" ]; then
        BACKUP_FILE="${STATE_FILE}.bak"
        cp -p "$STATE_FILE" "$BACKUP_FILE"
        log_info "Created configuration backup: $BACKUP_FILE"
    fi

    log_info "Patching profile state for ${COLOR_BOLD}$CHANNEL_NAME${COLOR_RESET}..."

    # Engine 1: Native macOS JXA via osascript
    if command -v osascript >/dev/null 2>&1; then
        OSASCRIPT_OUT=$(osascript -l JavaScript 2>&1 <<JXA_EOF "$STATE_FILE"
function run(argv) {
    ObjC.import('Foundation');
    var path = argv[0];
    var pathStr = $(path);
    var fm = $.NSFileManager.defaultManager;
    var raw = "";

    if (fm.fileExistsAtPath(pathStr)) {
        var err = $();
        var nsData = $.NSString.stringWithContentsOfFileEncodingError(pathStr, $.NSUTF8StringEncoding, err);
        if (nsData) {
            raw = ObjC.unwrap(nsData);
        }
    }

    var data = {};
    if (raw && raw.trim().length > 0) {
        try {
            if (raw.charCodeAt(0) === 0xFEFF) {
                raw = raw.slice(1);
            }
            data = JSON.parse(raw);
        } catch(e) {
            data = {};
        }
    }

    if (!data.brave || typeof data.brave !== 'object') {
        data.brave = {};
    }
    data.brave.origin = { purchase_validated: true };

    if (!data.skus || typeof data.skus !== 'object') {
        data.skus = {};
    }
    data.skus.state = {
        "67": JSON.stringify({
            credentials: {
                items: { "6": "7" }
            }
        })
    };

    var updatedJson = JSON.stringify(data, null, 2);
    var outStr = $(updatedJson);
    var writeSuccess = outStr.writeToFileAtomicallyEncodingError(pathStr, true, $.NSUTF8StringEncoding, null);
    if (!writeSuccess) {
        throw new Error("Unable to write file atomically: " + path);
    }
    return "SUCCESS";
}
JXA_EOF
)
        if [ "$OSASCRIPT_OUT" = "SUCCESS" ]; then
            # Verify JSON integrity with native plutil
            if command -v plutil >/dev/null 2>&1; then
                plutil -lint "$STATE_FILE" >/dev/null 2>&1 || {
                    log_error "JSON validation failed for $STATE_FILE."
                    return 1
                }
            fi
            log_success "Successfully configured profile state for ${COLOR_BOLD}$CHANNEL_NAME${COLOR_RESET}!"
            return 0
        fi
        log_warn "JXA engine reported: $OSASCRIPT_OUT. Attempting secondary fallback engine..."
    fi

    # Engine 2: Python 3 fallback (if available without developer prompt)
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import json, sys
p = sys.argv[1]
try:
    with open(p, 'r', encoding='utf-8') as f:
        d = json.load(f)
except Exception:
    d = {}
if 'brave' not in d or not isinstance(d['brave'], dict):
    d['brave'] = {}
d['brave']['origin'] = {'purchase_validated': True}
if 'skus' not in d or not isinstance(d['skus'], dict):
    d['skus'] = {}
d['skus']['state'] = {'67': json.dumps({'credentials': {'items': {'6': '7'}}})}
with open(p, 'w', encoding='utf-8') as f:
    json.dump(d, f, indent=2)
" "$STATE_FILE" 2>/dev/null; then
            log_success "Successfully configured profile state for ${COLOR_BOLD}$CHANNEL_NAME${COLOR_RESET} (via Python3 engine)!"
            return 0
        fi
    fi

    log_error "Failed to patch configuration for $CHANNEL_NAME. No compatible JSON engine succeeded."
    return 1
}

# --- Restore Operation ---
restore_local_state() {
    STATE_FILE="$1"
    CHANNEL_NAME="$2"
    BACKUP_FILE="${STATE_FILE}.bak"

    if [ -f "$BACKUP_FILE" ]; then
        cp -p "$BACKUP_FILE" "$STATE_FILE"
        log_success "Restored original configuration for ${COLOR_BOLD}$CHANNEL_NAME${COLOR_RESET} from backup."
        return 0
    else
        log_warn "No backup file found at: $BACKUP_FILE"
        return 1
    fi
}

# --- Channel Detection & Mapping ---
run_pipeline() {
    BASE_SUPPORT="$HOME/Library/Application Support/BraveSoftware"

    CHANNELS_TO_PROCESS=""
    case "$CHANNEL" in
        Release)
            CHANNELS_TO_PROCESS="Brave-Origin"
            ;;
        Beta)
            CHANNELS_TO_PROCESS="Brave-Origin-Beta"
            ;;
        Nightly)
            CHANNELS_TO_PROCESS="Brave-Origin-Nightly"
            ;;
        All)
            CHANNELS_TO_PROCESS="Brave-Origin Brave-Origin-Beta Brave-Origin-Nightly"
            ;;
        *)
            log_error "Invalid channel: $CHANNEL. Must be Release, Beta, Nightly, or All."
            exit 1
            ;;
    esac

    # Handle custom User Data path
    if [ -n "$CUSTOM_PATH" ]; then
        stop_running_brave
        CUSTOM_STATE="$CUSTOM_PATH/Local State"
        if [ $RESTORE_FLAG -eq 1 ]; then
            restore_local_state "$CUSTOM_STATE" "Custom ($CUSTOM_PATH)"
        else
            patch_local_state "$CUSTOM_STATE" "Custom ($CUSTOM_PATH)"
        fi
        return 0
    fi

    # Scan for existing installations
    FOUND_COUNT=0
    for ch in $CHANNELS_TO_PROCESS; do
        STATE_PATH="$BASE_SUPPORT/$ch/Local State"
        APP_PATH_1="/Applications/$ch.app"
        APP_PATH_2="/Applications/$(echo "$ch" | sed 's/-/ /g').app"
        APP_PATH_3="$HOME/Applications/$(echo "$ch" | sed 's/-/ /g').app"

        if [ -f "$STATE_PATH" ] || [ -d "$APP_PATH_1" ] || [ -d "$APP_PATH_2" ] || [ -d "$APP_PATH_3" ]; then
            FOUND_COUNT=$((FOUND_COUNT + 1))
        fi
    done

    # If none found and --install flag provided, trigger installation
    if [ $FOUND_COUNT -eq 0 ]; then
        log_warn "No Brave Origin installations detected on this system."
        if [ $INSTALL_FLAG -eq 1 ]; then
            install_brave_origin
            FOUND_COUNT=1
        else
            printf "Would you like to download and install Brave Origin now? [Y/n]: "
            read -r resp
            case "$resp" in
                [nN][oO]|[nN])
                    log_info "Installation skipped. You can initialize configuration manually."
                    ;;
                *)
                    install_brave_origin
                    FOUND_COUNT=1
                    ;;
            esac
        fi
    fi

    # Terminate running instances before modifying files
    stop_running_brave

    PROCESSED=0
    for ch in $CHANNELS_TO_PROCESS; do
        STATE_PATH="$BASE_SUPPORT/$ch/Local State"
        CH_DISPLAY="$(echo "$ch" | sed 's/-/ /g')"

        # Apply to channels that are either installed or targeted
        if [ $FOUND_COUNT -eq 0 ] && [ "$CHANNEL" = "All" ]; then
            # If nothing installed and user chose not to install, patch default Release path
            if [ "$ch" != "Brave-Origin" ]; then
                continue
            fi
        fi

        if [ $RESTORE_FLAG -eq 1 ]; then
            restore_local_state "$STATE_PATH" "$CH_DISPLAY" && PROCESSED=$((PROCESSED + 1)) || true
        else
            patch_local_state "$STATE_PATH" "$CH_DISPLAY" && PROCESSED=$((PROCESSED + 1)) || true
        fi
    done

    if [ $PROCESSED -gt 0 ]; then
        if [ $RESTORE_FLAG -eq 1 ]; then
            log_success "Restore completed for $PROCESSED channel(s)."
        else
            log_success "Profile state configuration successfully applied to $PROCESSED channel(s)!"
        fi
    else
        log_warn "No channels were modified. Run with --help for available options."
    fi
}

# --- Main Entry Point ---
main() {
    printf "\n"
    printf "${COLOR_BOLD}======================================================${COLOR_RESET}\n"
    printf "${COLOR_BOLD}   Brave Origin Profile Configuration Tool (macOS)   ${COLOR_RESET}\n"
    printf "${COLOR_BOLD}======================================================${COLOR_RESET}\n\n"

    detect_environment
    run_pipeline

    printf "\n${COLOR_GREEN}[✔] Execution finished.${COLOR_RESET}\n\n"
}

main "$@"
