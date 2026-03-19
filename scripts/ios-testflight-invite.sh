#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
API_BASE="https://api.appstoreconnect.apple.com"

DEFAULT_BUNDLE_ID="com.hushhone.hushh.agent"
DEFAULT_GROUP_NAME="Hushh Agent External"

BUNDLE_ID="$DEFAULT_BUNDLE_ID"
MARKETING_VERSION=""
BUILD_NUMBER=""
GROUP_NAME="$DEFAULT_GROUP_NAME"
MODE="external"

EMAILS=()

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} Hushh Agent TestFlight Invites${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

usage() {
    cat <<EOF
Usage:
  $0 [options] --email user@example.com [--email user2@example.com ...]
  $0 [options] user1@example.com user2@example.com

Options:
  --bundle-id <id>       App bundle identifier. Default: ${DEFAULT_BUNDLE_ID}
  --version <version>    Marketing version. Default: read from project.yml
  --build <number>       Build number. Default: read from project.yml
  --group-name <name>    External beta group name. Default: ${DEFAULT_GROUP_NAME}
  --mode <mode>          Only "external" is supported by this script today.
  --email <address>      Tester email. Repeat for multiple testers.
  --help                 Show this help.

Required environment:
  APP_STORE_API_KEY_ID
  APP_STORE_ISSUER_ID
  APP_STORE_API_KEY_FILE

Example:
  APP_STORE_API_KEY_ID=... APP_STORE_ISSUER_ID=... APP_STORE_API_KEY_FILE=... \\
  $0 --version 1.0.2 --build 141 \\
    --email ankit@hushh.ai --email manish@hushh.ai
EOF
}

require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo -e "${RED}Missing required tool: $1${NC}"
        exit 1
    fi
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

json_escape() {
    jq -Rn --arg value "$1" '$value'
}

uri_encode() {
    jq -nr --arg value "$1" '$value|@uri'
}

generate_token() {
    ruby <<'RUBY'
require "base64"
require "json"
require "openssl"

def b64url(value)
  Base64.urlsafe_encode64(value, padding: false)
end

key_id = ENV.fetch("APP_STORE_API_KEY_ID")
issuer_id = ENV.fetch("APP_STORE_ISSUER_ID")
key_path = ENV.fetch("APP_STORE_API_KEY_FILE")
now = Time.now.to_i

header = { alg: "ES256", kid: key_id, typ: "JWT" }
payload = {
  iss: issuer_id,
  iat: now,
  exp: now + 1200,
  aud: "appstoreconnect-v1"
}

encoded_header = b64url(header.to_json)
encoded_payload = b64url(payload.to_json)
signing_input = "#{encoded_header}.#{encoded_payload}"

private_key = OpenSSL::PKey.read(File.read(key_path))
der_signature = private_key.dsa_sign_asn1(OpenSSL::Digest::SHA256.digest(signing_input))
asn1 = OpenSSL::ASN1.decode(der_signature)
r = asn1.value[0].value.to_s(2).rjust(32, "\x00")
s = asn1.value[1].value.to_s(2).rjust(32, "\x00")
raw_signature = r + s

puts "#{signing_input}.#{b64url(raw_signature)}"
RUBY
}

API_STATUS=""
API_BODY=""

api_request() {
    local method="$1"
    local path="$2"
    local body="${3:-}"
    local response_file
    local error_file
    local auth_token
    local curl_args
    local curl_exit

    response_file="$(mktemp)"
    error_file="$(mktemp)"
    auth_token="$(generate_token)"

    curl_args=(
        -sS
        -X "$method"
        -H "Authorization: Bearer $auth_token"
        -H "Accept: application/json"
        -o "$response_file"
        -w "%{http_code}"
        "$API_BASE$path"
    )

    if [ -n "$body" ]; then
        curl_args=(
            -sS
            -X "$method"
            -H "Authorization: Bearer $auth_token"
            -H "Accept: application/json"
            -H "Content-Type: application/json"
            --data "$body"
            -o "$response_file"
            -w "%{http_code}"
            "$API_BASE$path"
        )
    fi

    set +e
    API_STATUS="$(curl "${curl_args[@]}" 2>"$error_file")"
    curl_exit=$?
    set -e

    if [ "$curl_exit" -ne 0 ]; then
        echo -e "${RED}Network request failed while calling:${NC} $path" >&2
        cat "$error_file" >&2
        rm -f "$response_file" "$error_file"
        exit 1
    fi

    API_BODY="$(cat "$response_file")"
    rm -f "$response_file" "$error_file"
}

print_api_error_and_exit() {
    local context="$1"
    local summary
    summary="$(jq -r '[.errors[]? | [.status // "", .code // "", .title // "", .detail // ""] | join(" | ")] | join("\n")' <<<"$API_BODY" 2>/dev/null || true)"
    echo -e "${RED}${context} failed (HTTP ${API_STATUS}).${NC}" >&2
    if [ -n "$summary" ] && [ "$summary" != "null" ]; then
        echo "$summary" >&2
    elif [ -n "$API_BODY" ]; then
        echo "$API_BODY" >&2
    fi
    exit 1
}

require_success() {
    local context="$1"
    if [[ ! "$API_STATUS" =~ ^2 ]]; then
        print_api_error_and_exit "$context"
    fi
}

warn_on_non_success() {
    local context="$1"
    if [[ ! "$API_STATUS" =~ ^2 ]]; then
        local summary
        summary="$(jq -r '[.errors[]? | [.status // "", .code // "", .title // "", .detail // ""] | join(" | ")] | join("\n")' <<<"$API_BODY" 2>/dev/null || true)"
        echo -e "${YELLOW}${context} did not complete cleanly (HTTP ${API_STATUS}).${NC}" >&2
        if [ -n "$summary" ] && [ "$summary" != "null" ]; then
            echo "$summary" >&2
        elif [ -n "$API_BODY" ]; then
            echo "$API_BODY" >&2
        fi
    fi
}

find_app_id() {
    api_request GET "/v1/apps?filter%5BbundleId%5D=$(uri_encode "$BUNDLE_ID")&limit=1"
    require_success "Lookup app"
    jq -r '.data[0].id // empty' <<<"$API_BODY"
}

find_build_id() {
    local app_id="$1"
    local builds_json build_id

    api_request GET "/v1/builds?filter%5Bapp%5D=$(uri_encode "$app_id")&include=preReleaseVersion&limit=200"
    require_success "Lookup builds"
    builds_json="$API_BODY"

    build_id="$(
        jq -r \
            --arg marketing "$MARKETING_VERSION" \
            --arg build "$BUILD_NUMBER" '
                .included as $included
                | [
                    .data[]
                    | . as $buildRow
                    | (
                        $included[]?
                        | select(.type == "preReleaseVersions" and .id == ($buildRow.relationships.preReleaseVersion.data.id // ""))
                        | .attributes.version
                      ) as $marketingVersion
                    | select(($buildRow.attributes.version // "") == $build and ($marketingVersion // "") == $marketing)
                    | $buildRow.id
                  ][0] // empty
            ' <<<"$builds_json"
    )"

    printf '%s' "$build_id"
}

load_groups_json() {
    local app_id="$1"
    api_request GET "/v1/apps/$app_id/betaGroups?limit=200"
    require_success "Lookup beta groups"
    printf '%s' "$API_BODY"
}

find_group_id() {
    local groups_json="$1"
    jq -r --arg name "$GROUP_NAME" '
        [.data[]
         | select((.attributes.name // "") == $name and (.attributes.isInternalGroup // false) == false)
         | .id][0] // empty
    ' <<<"$groups_json"
}

count_internal_groups() {
    local groups_json="$1"
    jq -r '[.data[] | select((.attributes.isInternalGroup // false) == true)] | length' <<<"$groups_json"
}

create_external_group() {
    local app_id="$1"
    local payload

    payload="$(jq -nc \
        --arg name "$GROUP_NAME" \
        --arg app_id "$app_id" '
            {
              data: {
                type: "betaGroups",
                attributes: {
                  name: $name,
                  isInternalGroup: false,
                  publicLinkEnabled: false,
                  publicLinkLimitEnabled: false,
                  feedbackEnabled: true
                },
                relationships: {
                  app: {
                    data: { type: "apps", id: $app_id }
                  }
                }
              }
            }
        ')"

    api_request POST "/v1/betaGroups" "$payload"
    require_success "Create external beta group"
    jq -r '.data.id // empty' <<<"$API_BODY"
}

add_build_to_group() {
    local group_id="$1"
    local build_id="$2"
    local payload

    payload="$(jq -nc --arg build_id "$build_id" '{data: [{type: "builds", id: $build_id}]}' )"
    api_request POST "/v1/betaGroups/$group_id/relationships/builds" "$payload"
    if [[ "$API_STATUS" = "409" ]]; then
        echo -e "${YELLOW}Build is already attached to beta group.${NC}"
        return 0
    fi
    require_success "Attach build to beta group"
}

find_beta_tester_id() {
    local email="$1"
    api_request GET "/v1/betaTesters?filter%5Bemail%5D=$(uri_encode "$email")&limit=1"
    require_success "Lookup beta tester $email"
    jq -r '.data[0].id // empty' <<<"$API_BODY"
}

name_part() {
    local value="$1"
    awk '{
        if (length($0) == 0) {
            print "Tester"
        } else {
            print toupper(substr($0,1,1)) substr($0,2)
        }
    }' <<<"$value"
}

default_first_name() {
    local email="$1"
    local local_part="${email%@*}"
    local token
    token="$(tr '._-' ' ' <<<"$local_part" | awk '{print $1}')"
    name_part "$token"
}

default_last_name() {
    local email="$1"
    local local_part="${email%@*}"
    local rest
    rest="$(tr '._-' ' ' <<<"$local_part" | awk '{$1=""; sub(/^ /,""); print}')"
    if [ -n "$rest" ]; then
        name_part "$rest"
    else
        echo "Tester"
    fi
}

create_beta_tester() {
    local app_id="$1"
    local group_id="$2"
    local email="$3"
    local first_name last_name payload

    first_name="$(default_first_name "$email")"
    last_name="$(default_last_name "$email")"

    payload="$(jq -nc \
        --arg group_id "$group_id" \
        --arg email "$email" \
        --arg first_name "$first_name" \
        --arg last_name "$last_name" '
            {
              data: {
                type: "betaTesters",
                attributes: {
                  email: $email,
                  firstName: $first_name,
                  lastName: $last_name
                },
                relationships: {
                  betaGroups: {
                    data: [{ type: "betaGroups", id: $group_id }]
                  }
                }
              }
            }
        ')"

    api_request POST "/v1/betaTesters" "$payload"
    require_success "Create beta tester $email"
    jq -r '.data.id // empty' <<<"$API_BODY"
}

add_tester_to_group() {
    local tester_id="$1"
    local group_id="$2"
    local payload

    payload="$(jq -nc --arg group_id "$group_id" '{data: [{type: "betaGroups", id: $group_id}]}' )"
    api_request POST "/v1/betaTesters/$tester_id/relationships/betaGroups" "$payload"
    if [[ "$API_STATUS" = "409" ]]; then
        echo -e "${YELLOW}Tester is already in beta group.${NC}"
        return 0
    fi
    require_success "Add tester to beta group"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --bundle-id)
            BUNDLE_ID="$2"
            shift 2
            ;;
        --version)
            MARKETING_VERSION="$2"
            shift 2
            ;;
        --build)
            BUILD_NUMBER="$2"
            shift 2
            ;;
        --group-name)
            GROUP_NAME="$2"
            shift 2
            ;;
        --mode)
            MODE="$2"
            shift 2
            ;;
        --email)
            EMAILS+=("$2")
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            EMAILS+=("$1")
            shift
            ;;
    esac
done

print_header

require_tool jq
require_tool curl
require_tool ruby

if [ "$MODE" != "external" ]; then
    echo -e "${RED}Only external email-based TestFlight invites are automated by this script today.${NC}"
    echo "Internal testers must already be App Store Connect users."
    exit 1
fi

if [ ${#EMAILS[@]} -eq 0 ]; then
    echo -e "${RED}Provide at least one tester email.${NC}"
    usage
    exit 1
fi

: "${APP_STORE_API_KEY_ID:?Set APP_STORE_API_KEY_ID}"
: "${APP_STORE_ISSUER_ID:?Set APP_STORE_ISSUER_ID}"
: "${APP_STORE_API_KEY_FILE:?Set APP_STORE_API_KEY_FILE}"

if [ ! -f "$APP_STORE_API_KEY_FILE" ]; then
    echo -e "${RED}API key file not found:${NC} $APP_STORE_API_KEY_FILE"
    exit 1
fi

if [ -z "$MARKETING_VERSION" ]; then
    MARKETING_VERSION="$(project_yaml_value MARKETING_VERSION)"
fi

if [ -z "$BUILD_NUMBER" ]; then
    BUILD_NUMBER="$(project_yaml_value CURRENT_PROJECT_VERSION)"
fi

if [ -z "$MARKETING_VERSION" ] || [ -z "$BUILD_NUMBER" ]; then
    echo -e "${RED}Could not determine version/build. Pass --version and --build explicitly.${NC}"
    exit 1
fi

echo -e "${YELLOW}Invite settings${NC}"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Version:   $MARKETING_VERSION ($BUILD_NUMBER)"
echo "  Group:     $GROUP_NAME"
echo "  Mode:      $MODE"
echo "  Testers:   ${EMAILS[*]}"
echo ""

echo -e "${YELLOW}Looking up app...${NC}"
APP_ID="$(find_app_id)"
if [ -z "$APP_ID" ]; then
    echo -e "${RED}No App Store Connect app found for bundle ID:${NC} $BUNDLE_ID"
    exit 1
fi

echo -e "${GREEN}App found:${NC} $APP_ID"

echo -e "${YELLOW}Looking up build...${NC}"
BUILD_ID="$(find_build_id "$APP_ID")"
if [ -z "$BUILD_ID" ]; then
    echo -e "${RED}No build found for ${MARKETING_VERSION} (${BUILD_NUMBER}).${NC}"
    echo "The build may still be processing in App Store Connect."
    exit 1
fi

echo -e "${GREEN}Build found:${NC} $BUILD_ID"

echo -e "${YELLOW}Loading beta groups...${NC}"
GROUPS_JSON="$(load_groups_json "$APP_ID")"
INTERNAL_GROUP_COUNT="$(count_internal_groups "$GROUPS_JSON")"
if [ "$INTERNAL_GROUP_COUNT" -eq 0 ]; then
    echo -e "${RED}Apple requires at least one internal tester group before creating an external group.${NC}"
    echo "Create any internal TestFlight group once in App Store Connect, then rerun this script."
    exit 1
fi

GROUP_ID="$(find_group_id "$GROUPS_JSON")"
if [ -z "$GROUP_ID" ]; then
    echo -e "${YELLOW}Creating external beta group...${NC}"
    GROUP_ID="$(create_external_group "$APP_ID")"
else
    echo -e "${GREEN}Using existing beta group:${NC} $GROUP_ID"
fi

echo -e "${YELLOW}Attaching build to beta group...${NC}"
add_build_to_group "$GROUP_ID" "$BUILD_ID"

echo ""
for email in "${EMAILS[@]}"; do
    echo -e "${BLUE}Processing tester:${NC} $email"
    TESTER_ID="$(find_beta_tester_id "$email")"
    if [ -z "$TESTER_ID" ]; then
        TESTER_ID="$(create_beta_tester "$APP_ID" "$GROUP_ID" "$email")"
        echo "  Created beta tester: $TESTER_ID"
    else
        echo "  Existing beta tester: $TESTER_ID"
    fi

    add_tester_to_group "$TESTER_ID" "$GROUP_ID"
done

echo ""
echo -e "${GREEN}Invite automation finished.${NC}"
echo "Apple sends external email invites once the tester is in the group and the build is available for that external group."
echo "If Apple hasn't approved this build for external testing yet, email delivery can still wait until approval."
