<div align="center">

# SaveSpace

[![macOS](https://img.shields.io/badge/macOS-15.0+-blue.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)](https://developer.apple.com/macos/)

**Reclaim storage by converting Live Photos to standard photos while preserving metadata.**

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Documentation](#documentation) • [Contributing](#contributing)

</div>

---

## Screenshots

| Photo Grid | Conversion Options |
|:----------:|:------------------:|
| Browse and select Live Photos | Choose export and conversion settings |

## Features

- 📸 **Browse Live Photos** — View all Live Photos with sidebar filters by date and album
- ✅ **Bulk Selection** — Select individual photos or all at once
- 🔄 **Smart Conversion** — Preserves Long Exposure effects, key frame selection, and all metadata
- 💾 **Export Options** — Export video clips (.MOV) or original HEIC files before conversion
- 📊 **Space Estimation** — See estimated storage savings before converting
- 🔒 **Privacy First** — All processing happens locally, nothing is uploaded

## Requirements

| Requirement | Version |
|-------------|---------|
| macOS | 15.0 (Sequoia) or later |
| Xcode | 16.0 or later |
| Swift | 5.9 or later |

## Installation

### Download Release (Recommended)

1. Go to the [Releases](https://github.com/vikas-0/SaveSpace/releases) page
2. Download the latest `SaveSpace-x.x.x.dmg`
3. Open the DMG and drag SaveSpace to Applications
4. Launch from Applications folder

### Build from Source

```bash
# Clone the repository
git clone https://github.com/vikas-0/SaveSpace.git
cd SaveSpace

# Build and run (choose one)
make build    # Debug build
make release  # Release build
make dmg      # Create distributable DMG
make run      # Build and run

# Or open in Xcode
open SaveSpace.xcodeproj
```

## Usage

### Quick Start

1. **Launch** — Open SaveSpace from Applications
2. **Grant Permissions** — Allow Full Access to Photos when prompted
3. **Browse** — Use sidebar to filter by date or album
4. **Select** — Click photos to select (or "Select All")
5. **Convert** — Click Convert button and choose options

### Conversion Options

| Option | Description |
|--------|-------------|
| **Convert to Standard Photo** | Removes video component, preserves all edits and metadata |
| **Export Video First** | Saves `.MOV` video clip before conversion |
| **Export Original First** | Saves original Live Photo before conversion |

### What Gets Preserved

- ✅ Creation date and time
- ✅ Location data (GPS)
- ✅ Favorite status
- ✅ Long Exposure effect
- ✅ Selected key frame
- ✅ Other photo edits

## Permissions

SaveSpace requires **Full Access** to your Photos library:

| Permission | Purpose |
|------------|---------|
| Read Access | Browse and display Live Photos |
| Write Access | Convert photos and update library |

> **Note:** SaveSpace only modifies photos you explicitly select for conversion.

## Documentation

- 📖 [Architecture Guide](docs/ARCHITECTURE.md) — Project structure and design patterns
- 🔧 [Development Guide](docs/DEVELOPMENT.md) — Setup and contribution guidelines
- 📝 [API Documentation](docs/API.md) — Service and model documentation

## Project Structure

```
SaveSpace/
├── App/                        # App entry point and main views
│   ├── SaveSpaceApp.swift     # @main app definition
│   └── ContentView.swift      # Root view with navigation
├── Features/
│   ├── Sidebar/               # Album and date filter sidebar
│   ├── PhotoGrid/             # Photo browsing and selection
│   └── Conversion/            # Conversion UI and progress
├── Core/
│   ├── Services/              # Business logic
│   │   ├── PhotoKitService    # Photos framework integration
│   │   ├── ConversionService  # Live Photo conversion
│   │   └── ExportService      # File export functionality
│   ├── Models/                # Data structures
│   ├── Extensions/            # Swift extensions
│   └── Utilities/             # Helper functions
├── Resources/                 # Assets, icons, localization
└── scripts/                   # Build and utility scripts
```

## Privacy

SaveSpace is designed with privacy in mind:

- 🔒 **Offline Only** — No network requests, no analytics
- 🏠 **Local Processing** — All conversions happen on your Mac
- 👁️ **No Tracking** — No data collection whatsoever
- 🎯 **Explicit Selection** — Only processes photos you choose

## Contributing

Contributions are welcome! Please read our contributing guidelines:

1. Fork the repository
2. Create your feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Make your changes and test thoroughly
4. Commit with clear messages
   ```bash
   git commit -m 'Add amazing feature'
   ```
5. Push and open a Pull Request
   ```bash
   git push origin feature/amazing-feature
   ```

### Development Setup

```bash
# Install SwiftLint (optional but recommended)
brew install swiftlint

# Open project
open SaveSpace.xcodeproj

# Run tests
make test
```

## Roadmap

- [ ] Batch undo support
- [ ] iCloud Photos optimization
- [ ] Keyboard shortcuts
- [ ] Localization (multi-language support)

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/) and [PhotoKit](https://developer.apple.com/documentation/photokit)
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)

---

<div align="center">

**Made with ❤️ for macOS**

[Report Bug](https://github.com/vikas-0/SaveSpace/issues) • [Request Feature](https://github.com/vikas-0/SaveSpace/issues)

</div>
