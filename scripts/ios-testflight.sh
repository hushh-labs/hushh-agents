#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/HushhAgents.xcodeproj"
SCHEME="${IOS_TESTFLIGHT_SCHEME:-HushhAgents-Prod}"
CONFIGURATION="${IOS_TESTFLIGHT_CONFIGURATION:-Release Prod}"
ARCHIVE_PATH="$ROOT_DIR/build/HushhAgent.xcarchive"
EXPORT_PATH="$ROOT_DIR/build/export"
EXPORT_OPTIONS_PATH="$ROOT_DIR/ExportOptions.plist"
UPLOAD_WORKDIR="$ROOT_DIR/build/appstore-upload"

EXPECTED_APP_NAME="Hushh Agent"
EXPECTED_BUNDLE_ID="com.hushhone.hushh.agent"
EXPECTED_VERSION="${IOS_TESTFLIGHT_EXPECTED_VERSION:-1.0.2}"
EXPECTED_BUILD="${IOS_TESTFLIGHT_EXPECTED_BUILD:-143}"
EXPECTED_APPLE_ID="6736459877"
TEAM_ID="${APP_STORE_TEAM_ID:-WVDK9JW99C}"

NO_UPLOAD=false
SKIP_ARCHIVE=false
SKIP_EXPORT=false
ALLOW_PROVISIONING_UPDATES=false
INVITE_GROUP_NAME="${TESTFLIGHT_INVITE_GROUP_NAME:-}"
DEFAULT_INVITE_EMAILS=(
    "ankit@hushh.ai"
    "manish@hushh.ai"
    "jhumma@hushh.ai"
    "kushal@hushh.ai"
)
INVITE_EMAILS=("${DEFAULT_INVITE_EMAILS[@]}")

append_invite_email() {
    local email="$1"
    local existing

    if [ -z "$email" ]; then
        return 0
    fi

    for existing in "${INVITE_EMAILS[@]}"; do
        if [ "$existing" = "$email" ]; then
            return 0
        fi
    done

    INVITE_EMAILS+=("$email")
}

parse_invite_email_list() {
    local raw="$1"
    local normalized
    normalized="$(printf '%s' "$raw" | tr ',\n' '  ')"
    for email in $normalized; do
        append_invite_email "$email"
    done
}

while [ $# -gt 0 ]; do
    case "$1" in
        --no-upload)
            NO_UPLOAD=true
            ;;
        --skip-archive)
            SKIP_ARCHIVE=true
            ;;
        --skip-export)
            SKIP_EXPORT=true
            ;;
        --allow-provisioning-updates)
            ALLOW_PROVISIONING_UPDATES=true
            ;;
        --invite-email)
            append_invite_email "$2"
            shift 2
            continue
            ;;
        --invite-group-name)
            INVITE_GROUP_NAME="$2"
            shift 2
            continue
            ;;
        --help)
            echo "Usage: $0 [--no-upload] [--skip-archive] [--skip-export] [--allow-provisioning-updates] [--invite-email <email>] [--invite-group-name <name>]"
            echo ""
            echo "Default invite emails:"
            echo "  ankit@hushh.ai, manish@hushh.ai, jhumma@hushh.ai, kushal@hushh.ai"
            echo ""
            echo "Optional env:"
            echo "  TESTFLIGHT_INVITE_EMAILS     Comma- or newline-separated tester emails"
            echo "  TESTFLIGHT_INVITE_GROUP_NAME External beta group name"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
    shift
done

if [ -n "${TESTFLIGHT_INVITE_EMAILS:-}" ]; then
    parse_invite_email_list "${TESTFLIGHT_INVITE_EMAILS}"
fi

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} Hushh Agent TestFlight Automation${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo -e "${RED}Missing required tool: $1${NC}"
        exit 1
    fi
}

setting_value() {
    local key="$1"
    local settings
    settings="$(
        xcodebuild -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -showBuildSettings 2>/dev/null || true
    )"
    printf '%s\n' "$settings" | awk -F' = ' -v key="$key" '$1 ~ ("^[[:space:]]*" key "$") { print $2; exit }'
}

project_yaml_value() {
    local key="$1"
    if [ ! -f "$ROOT_DIR/project.yml" ]; then
        return 0
    fi

    awk -F': ' -v key="$key" '
        $1 ~ ("^[[:space:]]*" key "$") {
            gsub(/"/, "", $2)
            print $2
            exit
        }
    ' "$ROOT_DIR/project.yml"
}

discover_key_file() {
    local explicit_file="${APP_STORE_API_KEY_FILE:-}"
    local explicit_id="${APP_STORE_API_KEY_ID:-}"
    local file=""

    if [ -n "$explicit_file" ] && [ -f "$explicit_file" ]; then
        file="$explicit_file"
    elif [ -n "${APP_STORE_KEY_PATH:-}" ] && [ -n "$explicit_id" ] && [ -f "${APP_STORE_KEY_PATH}/AuthKey_${explicit_id}.p8" ]; then
        file="${APP_STORE_KEY_PATH}/AuthKey_${explicit_id}.p8"
    else
        for dir in \
            "$ROOT_DIR/private_keys" \
            "$HOME/.private_keys" \
            "$HOME/.appstoreconnect/private_keys" \
            "$HOME/private_keys" \
            "$HOME/Downloads"; do
            if [ -d "$dir" ]; then
                if [ -n "$explicit_id" ] && [ -f "$dir/AuthKey_${explicit_id}.p8" ]; then
                    file="$dir/AuthKey_${explicit_id}.p8"
                    break
                fi
                file="$(find "$dir" -maxdepth 1 -name 'AuthKey_*.p8' | head -1)"
                if [ -n "$file" ]; then
                    break
                fi
            fi
        done
    fi

    if [ -n "$file" ] && [ -f "$file" ]; then
        echo "$file"
    fi
}

prepare_upload_key_dir() {
    local source_key="$1"
    local key_id="$2"

    mkdir -p "$UPLOAD_WORKDIR/private_keys"
    ln -sf "$source_key" "$UPLOAD_WORKDIR/private_keys/AuthKey_${key_id}.p8"
}

print_header

require_tool xcodebuild
require_tool xcrun
require_tool find

API_KEY_FILE="$(discover_key_file || true)"
API_KEY_ID="${APP_STORE_API_KEY_ID:-}"
if [ -n "$API_KEY_FILE" ] && [ -z "$API_KEY_ID" ]; then
    API_KEY_ID="$(basename "$API_KEY_FILE" | sed 's/AuthKey_//' | sed 's/.p8//')"
fi
API_ISSUER_ID="${APP_STORE_ISSUER_ID:-}"

CURRENT_BUNDLE_ID="$(project_yaml_value PRODUCT_BUNDLE_IDENTIFIER)"
CURRENT_VERSION="$(project_yaml_value MARKETING_VERSION)"
CURRENT_BUILD="$(project_yaml_value CURRENT_PROJECT_VERSION)"

if [ -z "$CURRENT_BUNDLE_ID" ]; then
    CURRENT_BUNDLE_ID="$(setting_value PRODUCT_BUNDLE_IDENTIFIER)"
fi

if [ -z "$CURRENT_VERSION" ]; then
    CURRENT_VERSION="$(setting_value MARKETING_VERSION)"
fi

if [ -z "$CURRENT_BUILD" ]; then
    CURRENT_BUILD="$(setting_value CURRENT_PROJECT_VERSION)"
fi

echo -e "${YELLOW}Project settings${NC}"
echo "  App:       $EXPECTED_APP_NAME"
echo "  Apple ID:  $EXPECTED_APPLE_ID"
echo "  Bundle ID: $CURRENT_BUNDLE_ID"
echo "  Version:   $CURRENT_VERSION ($CURRENT_BUILD)"
echo "  Team ID:   $TEAM_ID"
echo ""

if [ "$CURRENT_BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ]; then
    echo -e "${RED}Bundle ID mismatch. Expected $EXPECTED_BUNDLE_ID but found $CURRENT_BUNDLE_ID.${NC}"
    exit 1
fi

if [ "$CURRENT_VERSION" != "$EXPECTED_VERSION" ] || [ "$CURRENT_BUILD" != "$EXPECTED_BUILD" ]; then
    echo -e "${YELLOW}Warning: project is not on the expected starting version ${EXPECTED_VERSION} (${EXPECTED_BUILD}).${NC}"
fi

ARCHIVE_ARGS=(
    -project "$PROJECT_PATH"
    -scheme "$SCHEME"
    -configuration "$CONFIGURATION"
    -destination "generic/platform=iOS"
    -archivePath "$ARCHIVE_PATH"
)

EXPORT_ARGS=(
    -exportArchive
    -archivePath "$ARCHIVE_PATH"
    -exportPath "$EXPORT_PATH"
    -exportOptionsPlist "$EXPORT_OPTIONS_PATH"
)

if [ "$ALLOW_PROVISIONING_UPDATES" = true ]; then
    ARCHIVE_ARGS+=(-allowProvisioningUpdates)
    EXPORT_ARGS+=(-allowProvisioningUpdates)
fi

if [ -n "$API_KEY_FILE" ] && [ -n "$API_KEY_ID" ] && [ -n "$API_ISSUER_ID" ]; then
    EXPORT_ARGS+=(
        -authenticationKeyPath "$API_KEY_FILE"
        -authenticationKeyID "$API_KEY_ID"
        -authenticationKeyIssuerID "$API_ISSUER_ID"
    )
fi

if [ "$SKIP_ARCHIVE" = false ]; then
    echo -e "${YELLOW}Archiving release build...${NC}"
    rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH" "$UPLOAD_WORKDIR"
    xcodebuild "${ARCHIVE_ARGS[@]}" archive
    echo -e "${GREEN}Archive created:${NC} $ARCHIVE_PATH"
    echo ""
else
    echo -e "${YELLOW}Skipping archive step.${NC}"
fi

if [ "$SKIP_EXPORT" = false ]; then
    echo -e "${YELLOW}Exporting IPA...${NC}"
    rm -rf "$EXPORT_PATH"
    xcodebuild "${EXPORT_ARGS[@]}"
else
    echo -e "${YELLOW}Skipping export step.${NC}"
fi

IPA_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -name '*.ipa' | head -1)"
if [ -z "$IPA_PATH" ] || [ ! -f "$IPA_PATH" ]; then
    if [ "$SKIP_EXPORT" = true ]; then
        echo -e "${RED}Skip-export was requested but no IPA was found in $EXPORT_PATH.${NC}"
    else
        echo -e "${RED}Export succeeded but no IPA was found in $EXPORT_PATH.${NC}"
    fi
    exit 1
fi

echo -e "${GREEN}IPA ready:${NC} $IPA_PATH"
echo ""

if [ "$NO_UPLOAD" = true ]; then
    echo -e "${GREEN}Upload skipped by request.${NC}"
    exit 0
fi

if [ -z "$API_KEY_FILE" ]; then
    echo -e "${YELLOW}No App Store Connect API key was found.${NC}"
    echo "Set APP_STORE_API_KEY_FILE or APP_STORE_API_KEY_ID/APP_STORE_KEY_PATH to enable uploads."
    echo "IPA remains available at: $IPA_PATH"
    exit 0
fi

prepare_upload_key_dir "$API_KEY_FILE" "$API_KEY_ID"

UPLOAD_ARGS=(
    --upload-app
    -f "$IPA_PATH"
    -t ios
    --apiKey "$API_KEY_ID"
)

if [ -n "$API_ISSUER_ID" ]; then
    UPLOAD_ARGS+=(--apiIssuer "$API_ISSUER_ID")
fi

echo -e "${YELLOW}Uploading to TestFlight...${NC}"
echo "  API key:   $API_KEY_ID"
if [ -n "$API_ISSUER_ID" ]; then
    echo "  Issuer ID: $API_ISSUER_ID"
else
    echo "  Issuer ID: not set, attempting individual-key upload"
fi
echo ""

mkdir -p "$ROOT_DIR/build"
UPLOAD_LOG="$ROOT_DIR/build/altool-upload.$(date +%Y%m%d-%H%M%S).log"
: > "$UPLOAD_LOG"
(
    cd "$UPLOAD_WORKDIR"
    xcrun altool "${UPLOAD_ARGS[@]}" 2>&1 | tee "$UPLOAD_LOG"
)

if grep -Eq "UPLOAD FAILED|Failed to upload package|Validation failed \(|AuthenticationFailure" "$UPLOAD_LOG"; then
    echo -e "${RED}TestFlight upload did not complete successfully. See:${NC} $UPLOAD_LOG"
    exit 1
fi

echo ""
echo -e "${GREEN}TestFlight upload completed for ${EXPECTED_APP_NAME} ${CURRENT_VERSION} (${CURRENT_BUILD}).${NC}"

if [ ${#INVITE_EMAILS[@]} -gt 0 ]; then
    local_invite_args=()
    for email in "${INVITE_EMAILS[@]}"; do
        local_invite_args+=(--email "$email")
    done

    if [ -n "$INVITE_GROUP_NAME" ]; then
        local_invite_args+=(--group-name "$INVITE_GROUP_NAME")
    fi

    echo ""
    echo -e "${YELLOW}Running TestFlight invite automation...${NC}"

    APP_STORE_API_KEY_ID="$API_KEY_ID" \
    APP_STORE_ISSUER_ID="$API_ISSUER_ID" \
    APP_STORE_API_KEY_FILE="$API_KEY_FILE" \
    "$ROOT_DIR/scripts/ios-testflight-invite.sh" \
        --bundle-id "$CURRENT_BUNDLE_ID" \
        --version "$CURRENT_VERSION" \
        --build "$CURRENT_BUILD" \
        "${local_invite_args[@]}"
fi
