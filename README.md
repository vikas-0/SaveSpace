# SaveSpace

A macOS app to reclaim storage by converting Live Photos to standard photos while preserving metadata.

## Features

- **Browse Live Photos** - View all Live Photos from your Photos library with sidebar filters by date and album
- **Bulk Selection** - Select individual photos or all at once
- **Smart Conversion** - Convert Live Photos to standard photos, removing the video component while preserving all metadata
- **Export Options** - Export video clips or original HEIC files before conversion
- **Space Estimation** - See estimated storage savings before converting

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Installation

### From DMG (Recommended)

Download the latest DMG from the [Releases](https://github.com/yourusername/SaveSpace/releases) page.

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/SaveSpace.git
   cd SaveSpace
   ```

2. Build using Make:
   ```bash
   make build    # Debug build
   make release  # Release build
   make dmg      # Create distributable DMG
   ```

   Or open in Xcode:
   ```bash
   open SaveSpace.xcodeproj
   ```

3. Build and run (⌘R)

## Permissions

SaveSpace requires access to your Photos library. On first launch, you'll be prompted to grant permission.

The app requires **Full Access** to:
- Read Live Photos from your library
- Modify photos (convert Live Photos to standard photos)
- Access photo metadata

## Usage

1. **Grant Permissions** - Allow access to your Photos library when prompted
2. **Browse** - Use the sidebar to filter by date or album
3. **Select** - Click photos to select, or use "Select All"
4. **Review** - Check the estimated space savings
5. **Convert** - Choose your options and convert

### Conversion Options

| Option | Description |
|--------|-------------|
| **Replace Original** | Converts in-place, preserving all metadata (default) |
| **Export Video** | Saves the video clip (.MOV) before removing it |
| **Export Original** | Saves the original Live Photo (.HEIC) before conversion |

## Architecture

```
SaveSpace/
├── App/                    # App entry point
├── Features/
│   ├── Sidebar/           # Album and date filters
│   ├── PhotoGrid/         # Photo browsing and selection
│   └── Conversion/        # Conversion options and progress
├── Core/
│   ├── Services/          # PhotoKit, Export, Conversion services
│   ├── Models/            # Data models
│   ├── Extensions/        # Swift extensions
│   └── Utilities/         # Helper utilities
└── Resources/             # Assets and localization
```

## Privacy

SaveSpace:
- Works entirely offline
- Never uploads your photos anywhere
- Only accesses photos you explicitly select
- All processing happens locally on your Mac

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI and PhotoKit
- Icons from SF Symbols
