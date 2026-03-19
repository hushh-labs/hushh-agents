#!/bin/bash

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <version> <build>"
    echo "Example: $0 1.0.2 140"
    exit 1
fi

VERSION="$1"
BUILD="$2"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/project.yml"

if ! [[ "$BUILD" =~ ^[0-9]+$ ]]; then
    echo "Build number must be numeric."
    exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen is required to sync HushhAgents.xcodeproj."
    exit 1
fi

perl -0pi -e 's/MARKETING_VERSION: "[^"]+"/MARKETING_VERSION: "'"$VERSION"'"/' "$PROJECT_FILE"
perl -0pi -e 's/CURRENT_PROJECT_VERSION: "[^"]+"/CURRENT_PROJECT_VERSION: "'"$BUILD"'"/' "$PROJECT_FILE"

cd "$ROOT_DIR"
xcodegen generate

echo "Updated iOS version to $VERSION ($BUILD)."
