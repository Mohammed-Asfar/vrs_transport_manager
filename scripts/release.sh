#!/bin/bash
# ─────────────────────────────────────────────────────────────
# VRS Transport Manager — Release Script
#
# Usage:
#   ./scripts/release.sh <version> "<release notes>"
#
# Examples:
#   ./scripts/release.sh 1.3.0 "Bug fixes and new machinery export"
#
# What it does:
#   1. Updates version in app_version.dart, pubspec.yaml, installer.iss
#   2. Builds Flutter Windows app locally
#   3. Compiles Inno Setup installer locally
#   4. Commits version bump, merges develop → main
#   5. Creates GitHub Release with .exe attached
#   6. GitHub Actions updates Firestore (triggered by push to main)
# ─────────────────────────────────────────────────────────────

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ISCC_PATH="D:/Software/Inno Setup 6/ISCC.exe"

cd "$PROJECT_DIR"

# ── Parse args ──────────────────────────────────────────────
VERSION="$1"
NOTES="$2"

if [ -z "$VERSION" ] || [ -z "$NOTES" ]; then
  echo "Usage: ./scripts/release.sh <version> \"<release notes>\""
  echo "  e.g. ./scripts/release.sh 1.3.0 \"Bug fixes and improvements\""
  exit 1
fi

if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Error: Version must be semver (e.g. 1.3.0)"
  exit 1
fi

# ── Verify we're on develop ─────────────────────────────────
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "develop" ]; then
  echo "Error: You must be on the 'develop' branch. Currently on '$BRANCH'."
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: You have uncommitted changes. Commit or stash them first."
  exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo "  VRS Transport Manager — Release v$VERSION"
echo "═══════════════════════════════════════════════════"
echo ""

# ── Step 1: Bump version ────────────────────────────────────
echo "▸ [1/6] Updating version to $VERSION..."

sed -i "s/static const String currentVersion = '.*'/static const String currentVersion = '$VERSION'/" \
  lib/core/utils/app_version.dart

CURRENT_BUILD=$(grep -oP 'version: [0-9.]+\+\K[0-9]+' pubspec.yaml || echo "0")
NEW_BUILD=$((CURRENT_BUILD + 1))
sed -i "s/^version: .*/version: $VERSION+$NEW_BUILD/" pubspec.yaml

sed -i "s/^AppVersion=.*/AppVersion=$VERSION/" installer.iss
sed -i "s/^OutputBaseFilename=.*/OutputBaseFilename=VRS_Transport_Manager_Setup_$VERSION/" installer.iss

echo "$NOTES" > RELEASE_NOTES.md

echo "  ✓ Version files updated"
echo ""

# ── Step 2: Build Flutter ────────────────────────────────────
echo "▸ [2/6] Building Flutter Windows app..."
flutter build windows --release
echo "  ✓ Build complete"
echo ""

# ── Step 3: Compile installer ────────────────────────────────
echo "▸ [3/6] Compiling Inno Setup installer..."
INSTALLER_FILE="VRS_Transport_Manager_Setup_$VERSION.exe"
"$ISCC_PATH" "$PROJECT_DIR/installer.iss"

if [ ! -f "$PROJECT_DIR/installer_output/$INSTALLER_FILE" ]; then
  echo "Error: Installer not found at installer_output/$INSTALLER_FILE"
  exit 1
fi

INSTALLER_SIZE=$(du -h "$PROJECT_DIR/installer_output/$INSTALLER_FILE" | cut -f1)
echo "  ✓ Installer: $INSTALLER_FILE ($INSTALLER_SIZE)"
echo ""

# ── Step 4: Commit and merge ─────────────────────────────────
echo "▸ [4/6] Committing and merging develop → main..."

git add lib/core/utils/app_version.dart pubspec.yaml installer.iss RELEASE_NOTES.md
git commit -m "release: v$VERSION"

git checkout main
git merge develop --no-ff -m "release: v$VERSION"
git push origin main
git checkout develop
git push origin develop

echo "  ✓ Merged and pushed"
echo ""

# ── Step 5: Upload to GitHub Releases ─────────────────────────
echo "▸ [5/6] Creating GitHub Release with installer..."

gh release create "v$VERSION" \
  "$PROJECT_DIR/installer_output/$INSTALLER_FILE" \
  --title "VRS Transport Manager v$VERSION" \
  --notes "$NOTES"

echo "  ✓ Release created"
echo ""

# ── Step 6: Done ─────────────────────────────────────────────
echo "▸ [6/6] GitHub Actions will update Firestore automatically"
echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✓ Release v$VERSION complete!"
echo "  → https://github.com/Mohammed-Asfar/vrs_transport_manager/releases/tag/v$VERSION"
echo "═══════════════════════════════════════════════════"
echo ""
