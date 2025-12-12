# Development Guide

This guide covers setting up your development environment and contributing to SaveSpace.

## Prerequisites

- **macOS 15.0+** (Sequoia)
- **Xcode 16.0+**
- **Swift 5.9+**
- **Git**

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/SaveSpace.git
cd SaveSpace
```

### 2. Open in Xcode

```bash
open SaveSpace.xcodeproj
```

### 3. Configure Signing

1. Select the SaveSpace target
2. Go to "Signing & Capabilities"
3. Select your Development Team
4. Xcode will automatically manage signing

### 4. Build and Run

Press `⌘R` or use the menu: Product → Run

## Project Configuration

### Build Settings

| Setting | Value |
|---------|-------|
| Deployment Target | macOS 15.0 |
| Swift Language Version | 5.9 |
| Build Configuration | Debug / Release |

### Entitlements

The app requires these entitlements (configured in `SaveSpace.entitlements`):

- `com.apple.security.app-sandbox` — App sandboxing
- `com.apple.security.files.user-selected.read-write` — File access
- `com.apple.security.personal-information.photos-library` — Photos access

### Info.plist Keys

| Key | Purpose |
|-----|---------|
| `NSPhotoLibraryUsageDescription` | Explains why Photos access is needed |

## Build Commands

Use the Makefile for common tasks:

```bash
# Debug build
make build

# Release build
make release

# Create DMG for distribution
make dmg

# Build and run
make run

# Clean build artifacts
make clean
```

## Code Style

### SwiftLint

The project uses SwiftLint for code style enforcement. Install it via Homebrew:

```bash
brew install swiftlint
```

Run manually:

```bash
swiftlint
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Types | PascalCase | `PhotoLibraryViewModel` |
| Functions/Variables | camelCase | `fetchAllLivePhotos()` |
| Constants | camelCase | `let maxThumbnailSize` |
| Protocols | PascalCase + able/ing | `Observable` |

### File Organization

```swift
// 1. Imports
import SwiftUI
import Photos

// 2. Type declaration
struct PhotoThumbnailView: View {
    // 3. Properties (in order)
    // - Constants/let
    // - @State
    // - @Binding
    // - @Environment
    
    // 4. Body
    var body: some View { ... }
    
    // 5. Private computed properties
    private var thumbnailImage: some View { ... }
    
    // 6. Private methods
    private func loadThumbnail() async { ... }
}

// 7. Previews
#Preview { ... }
```

## Architecture Guidelines

### Views

- Keep views thin — delegate logic to ViewModels
- Use `@ViewBuilder` for conditional content
- Prefer composition over large monolithic views

### ViewModels

- Mark with `@MainActor` for UI-bound state
- Use `@Published` for observable state
- Handle all business logic coordination

### Services

- Implement as `actor` for thread safety
- Use singleton pattern via `static let shared`
- Return results via `async` functions

## Testing

### Running Tests

```bash
# Via Xcode
⌘U

# Via command line
xcodebuild test -project SaveSpace.xcodeproj -scheme SaveSpace
```

### Writing Tests

```swift
import XCTest
@testable import SaveSpace

final class ConversionServiceTests: XCTestCase {
    func testVideoSizeCalculation() async {
        // Given
        let asset = createMockAsset()
        
        // When
        let size = await ConversionService.shared.calculateVideoSize(for: asset)
        
        // Then
        XCTAssertGreaterThan(size, 0)
    }
}
```

### Test Coverage Goals

| Layer | Target Coverage |
|-------|-----------------|
| Services | 80%+ |
| ViewModels | 70%+ |
| Models | 90%+ |

## Debugging

### Common Issues

#### "Photos access denied"

1. Go to System Preferences → Privacy & Security → Photos
2. Find SaveSpace and enable Full Access
3. Restart the app

#### Build fails with signing errors

1. Ensure you're signed into Xcode with your Apple ID
2. Select a valid Development Team
3. Clean build folder (`⌘⇧K`)

#### Thumbnails not loading

Check the console for PhotoKit errors. Ensure:
- Photos app has the images locally (not just in iCloud)
- Network access is available for iCloud photos

### Logging

Use structured logging:

```swift
import os

private let logger = Logger(subsystem: "com.savespace", category: "Conversion")

logger.info("Starting conversion of \(count) photos")
logger.error("Conversion failed: \(error.localizedDescription)")
```

## Creating a Release

### 1. Update Version

In Xcode, update:
- `MARKETING_VERSION` (e.g., "1.0.0")
- `CURRENT_PROJECT_VERSION` (e.g., "1")

### 2. Build Release

```bash
make dmg
```

### 3. Test the DMG

1. Open the generated DMG
2. Drag to Applications
3. Run and verify functionality

### 4. Create GitHub Release

See [RELEASING.md](RELEASING.md) for detailed instructions.

## Pull Request Guidelines

### Before Submitting

- [ ] Code compiles without warnings
- [ ] SwiftLint passes
- [ ] Tests pass
- [ ] UI tested manually
- [ ] Documentation updated if needed

### PR Description Template

```markdown
## Summary
Brief description of changes

## Changes
- Change 1
- Change 2

## Testing
How was this tested?

## Screenshots (if UI changes)
Before/After screenshots
```

## Getting Help

- **Issues**: Open a GitHub issue for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions
