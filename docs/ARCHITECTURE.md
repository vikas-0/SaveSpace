# Architecture Guide

This document describes the architecture and design patterns used in SaveSpace.

## Overview

SaveSpace follows the **MVVM (Model-View-ViewModel)** architecture pattern with a service layer for business logic. The app is built entirely with SwiftUI and leverages Swift's modern concurrency features (async/await, actors).

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         Views                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ SidebarView │  │PhotoGridView│  │ConversionOptionsSheet│ │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
          ▼                ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                      ViewModels                              │
│  ┌────────────────┐  ┌─────────────────────────────────┐    │
│  │SidebarViewModel│  │    PhotoLibraryViewModel        │    │
│  └───────┬────────┘  └──────────────┬──────────────────┘    │
└──────────┼──────────────────────────┼───────────────────────┘
           │                          │
           ▼                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       Services (Actors)                      │
│  ┌─────────────────┐ ┌──────────────────┐ ┌──────────────┐  │
│  │PhotoKitService  │ │ConversionService │ │ExportService │  │
│  └────────┬────────┘ └────────┬─────────┘ └──────┬───────┘  │
└───────────┼───────────────────┼──────────────────┼──────────┘
            │                   │                  │
            ▼                   ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                    PhotoKit Framework                        │
│         PHPhotoLibrary  │  PHAsset  │  PHAssetResource      │
└─────────────────────────────────────────────────────────────┘
```

## Layer Descriptions

### Views Layer

SwiftUI views responsible for UI rendering. Views are kept thin and delegate logic to ViewModels.

| View | Purpose |
|------|---------|
| `ContentView` | Root view with navigation and authorization handling |
| `SidebarView` | Album and date filter navigation |
| `PhotoGridView` | Grid display of Live Photos |
| `PhotoThumbnailView` | Individual photo thumbnail with selection |
| `ConversionOptionsSheet` | Conversion settings modal |
| `ConversionProgressView` | Progress display during conversion |

### ViewModels Layer

Observable objects that manage state and coordinate between views and services.

| ViewModel | Responsibilities |
|-----------|------------------|
| `PhotoLibraryViewModel` | Photo loading, selection, conversion orchestration |
| `SidebarViewModel` | Album and date group loading |

### Services Layer

Actor-based services that encapsulate business logic. Using actors ensures thread safety.

| Service | Purpose |
|---------|---------|
| `PhotoKitService` | PhotoKit integration, fetching photos/albums |
| `ConversionService` | Live Photo to standard photo conversion |
| `ExportService` | Exporting video/image files |

### Models Layer

Data structures used throughout the app.

| Model | Description |
|-------|-------------|
| `LivePhotoAsset` | Represents a Live Photo with metadata |
| `AlbumItem` | Photo album with Live Photo count |
| `DateGroup` | Photos grouped by date |
| `ConversionOptions` | User-selected conversion settings |
| `ConversionState` | Conversion progress state machine |

## Key Design Decisions

### 1. Actor-Based Services

Services are implemented as Swift actors to ensure thread-safe access:

```swift
actor PhotoKitService {
    static let shared = PhotoKitService()
    
    func fetchAllLivePhotos() async -> [LivePhotoAsset] {
        // Thread-safe implementation
    }
}
```

### 2. Async/Await Throughout

The app uses Swift's structured concurrency:

```swift
func convertSelectedPhotos(with options: ConversionOptions) async {
    let results = await ConversionService.shared.batchConvertWithSinglePrompt(
        assets: photosToConvert,
        options: options
    ) { current, total, saved in
        // Progress updates
    }
}
```

### 3. Batch Operations

To minimize permission prompts, conversions are batched:

1. Export all images to temp files (no prompts)
2. Create all new photos in one operation (1 prompt)
3. Delete all originals in one operation (1 prompt)

### 4. Rendered Image Export

Conversion preserves user edits by exporting the rendered version:

```swift
// Uses .current version to preserve Long Exposure, key frame, etc.
options.version = .current
imageManager.requestImageDataAndOrientation(for: asset, options: options)
```

## Data Flow

### Photo Loading Flow

```
1. App Launch
   ↓
2. PhotoLibraryViewModel.checkAuthorization()
   ↓
3. PhotoKitService.fetchAllLivePhotos()
   ↓
4. PhotoGridView displays photos
   ↓
5. PhotoThumbnailView loads thumbnails lazily
```

### Conversion Flow

```
1. User selects photos and taps Convert
   ↓
2. ConversionOptionsSheet shown
   ↓
3. User confirms options
   ↓
4. PhotoLibraryViewModel.convertSelectedPhotos()
   ↓
5. ConversionService.batchConvertWithSinglePrompt()
   ├─→ Export rendered images to temp
   ├─→ Create new standard photos (batch)
   └─→ Delete original Live Photos (batch)
   ↓
6. ConversionProgressView shows results
```

## Threading Model

| Context | Usage |
|---------|-------|
| `@MainActor` | ViewModels, UI updates |
| Actor isolation | Services (PhotoKitService, ConversionService) |
| Background | PhotoKit callbacks, file I/O |

## Error Handling

Errors are typed using Swift enums:

```swift
enum ConversionError: LocalizedError {
    case noVideoComponent
    case noImageComponent
    case failedToReadImage
    case photoLibraryError(underlying: Error)
}
```

## Testing Strategy

| Layer | Testing Approach |
|-------|------------------|
| Views | SwiftUI Previews |
| ViewModels | Unit tests with mock services |
| Services | Integration tests with test photos |

## Future Considerations

- **Unit Tests**: Add comprehensive test coverage
- **Dependency Injection**: Replace singletons with injected dependencies
- **Caching**: Implement thumbnail caching for performance
- **Undo Support**: Add ability to undo conversions
