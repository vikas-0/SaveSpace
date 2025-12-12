# Release Guide

This guide explains how to create and publish releases for SaveSpace.

## Version Numbering

SaveSpace uses [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

| Component | When to Increment |
|-----------|-------------------|
| MAJOR | Breaking changes, major redesigns |
| MINOR | New features, non-breaking changes |
| PATCH | Bug fixes, minor improvements |

## Pre-Release Checklist

- [ ] All tests pass
- [ ] No compiler warnings (except Swift 6 migration warnings)
- [ ] SwiftLint passes
- [ ] README is up to date
- [ ] CHANGELOG is updated
- [ ] Version numbers updated in Xcode

## Creating a Release

### 1. Update Version Numbers

In Xcode, select the SaveSpace target and update:

```
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
```

Or edit `SaveSpace.xcodeproj/project.pbxproj` directly.

### 2. Update CHANGELOG

Add entry to `CHANGELOG.md`:

```markdown
## [1.0.0] - 2024-01-15

### Added
- Initial release
- Live Photo browsing and filtering
- Batch conversion with metadata preservation
- Export options for video and original files
```

### 3. Commit and Tag

```bash
git add .
git commit -m "Release v1.0.0"
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin main --tags
```

### 4. Build the DMG

```bash
make dmg
```

This creates `build/SaveSpace-YYYY.MM.DD.dmg`

### 5. Create GitHub Release

#### Via GitHub Web UI

1. Go to your repository on GitHub
2. Click "Releases" in the right sidebar
3. Click "Draft a new release"
4. Fill in the details:

   **Tag:** `v1.0.0` (select existing tag)
   
   **Title:** `SaveSpace v1.0.0`
   
   **Description:**
   ```markdown
   ## What's New
   
   - Feature 1
   - Feature 2
   
   ## Installation
   
   1. Download `SaveSpace-1.0.0.dmg` below
   2. Open the DMG file
   3. Drag SaveSpace to your Applications folder
   4. Launch from Applications
   
   ## Requirements
   
   - macOS 15.0 (Sequoia) or later
   
   ## Checksums
   
   ```
   SHA256: <checksum>
   ```
   ```

5. Attach the DMG file
6. Click "Publish release"

#### Via GitHub CLI

```bash
# Install GitHub CLI if needed
brew install gh

# Authenticate
gh auth login

# Create release
gh release create v1.0.0 \
  --title "SaveSpace v1.0.0" \
  --notes-file release-notes.md \
  build/SaveSpace-*.dmg
```

### 6. Generate Checksum

```bash
shasum -a 256 build/SaveSpace-*.dmg
```

Include this in the release notes for verification.

## Post-Release

1. **Announce** — Post on relevant forums/social media
2. **Monitor** — Watch for issue reports
3. **Update docs** — Ensure website/docs reflect new version

## Hotfix Releases

For urgent bug fixes:

```bash
# Create hotfix branch from tag
git checkout -b hotfix/1.0.1 v1.0.0

# Make fixes
# ...

# Update version to 1.0.1
# Commit and tag
git commit -m "Hotfix v1.0.1: Fix critical bug"
git tag -a v1.0.1 -m "Hotfix release 1.0.1"

# Merge back to main
git checkout main
git merge hotfix/1.0.1
git push origin main --tags
```

## Automated Releases (Future)

Consider setting up GitHub Actions for automated releases:

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build DMG
        run: make dmg
        
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: build/*.dmg
```

## Troubleshooting

### DMG won't open on other Macs

The app needs to be signed and notarized for distribution:

```bash
# Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name" \
  build/Release/SaveSpace.app

# Create signed DMG
# ... (see Apple's notarization docs)
```

### Version mismatch

Ensure these match:
- Git tag
- MARKETING_VERSION in Xcode
- CHANGELOG entry
- GitHub release title
