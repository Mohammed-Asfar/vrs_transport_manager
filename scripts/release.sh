#!/bin/bash
# ─────────────────────────────────────────────────────────────
# VRS Transport Manager — Release Script
#
# Usage:
#   ./scripts/release.sh <version>
#
# Examples:
#   ./scripts/release.sh 1.3.0
#
# What it does (on develop branch):
#   1. Updates version in app_version.dart, pubspec.yaml, installer.iss
#   2. Commits the version bump
#   3. Merges develop → main and pushes
#   4. Switches back to develop
#   5. GitHub Actions takes over: build → installer → release → Firestore
# ─────────────────────────────────────────────────────────────

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# ── Parse args ──────────────────────────────────────────────
VERSION="$1"

if [ -z "$VERSION" ]; then
  echo "Usage: ./scripts/release.sh <version>"
  echo "  e.g. ./scripts/release.sh 1.3.0"
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
echo "▸ [1/4] Updating version to $VERSION..."

sed -i "s/static const String currentVersion = '.*'/static const String currentVersion = '$VERSION'/" \
  lib/core/utils/app_version.dart

CURRENT_BUILD=$(grep -oP 'version: [0-9.]+\+\K[0-9]+' pubspec.yaml || echo "0")
NEW_BUILD=$((CURRENT_BUILD + 1))
sed -i "s/^version: .*/version: $VERSION+$NEW_BUILD/" pubspec.yaml

sed -i "s/^AppVersion=.*/AppVersion=$VERSION/" installer.iss
sed -i "s/^OutputBaseFilename=.*/OutputBaseFilename=VRS_Transport_Manager_Setup_$VERSION/" installer.iss

echo "  ✓ app_version.dart → $VERSION"
echo "  ✓ pubspec.yaml → $VERSION+$NEW_BUILD"
echo "  ✓ installer.iss → $VERSION"
echo ""

# ── Step 2: Commit on develop ───────────────────────────────
echo "▸ [2/4] Committing version bump on develop..."

git add lib/core/utils/app_version.dart pubspec.yaml installer.iss
git commit -m "release: v$VERSION"
echo "  ✓ Committed on develop"
echo ""

# ── Step 3: Merge into main ─────────────────────────────────
echo "▸ [3/4] Merging develop → main..."

git checkout main
git merge develop --no-ff -m "release: v$VERSION"
git push origin main
git checkout develop
git push origin develop

echo "  ✓ Merged and pushed"
echo ""

# ── Step 4: Done ────────────────────────────────────────────
echo "▸ [4/4] Back on develop branch"
echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✓ GitHub Actions is now building v$VERSION!"
echo "  → https://github.com/Mohammed-Asfar/vrs_transport_manager/actions"
echo "═══════════════════════════════════════════════════"
echo ""
