# API Documentation

This document provides detailed documentation for SaveSpace's services and models.

## Services

### PhotoKitService

Actor-based service for interacting with the Photos framework.

```swift
actor PhotoKitService {
    static let shared = PhotoKitService()
}
```

#### Methods

##### `checkAuthorizationStatus()`

Returns the current Photos library authorization status.

```swift
func checkAuthorizationStatus() -> PHAuthorizationStatus
```

**Returns:** `PHAuthorizationStatus` — Current authorization state

---

##### `requestAuthorization()`

Requests Photos library access from the user.

```swift
func requestAuthorization() async -> PHAuthorizationStatus
```

**Returns:** `PHAuthorizationStatus` — Resulting authorization state

---

##### `fetchAllLivePhotos()`

Fetches all Live Photos from the user's library.

```swift
func fetchAllLivePhotos() async -> [LivePhotoAsset]
```

**Returns:** Array of `LivePhotoAsset` sorted by creation date (newest first)

---

##### `fetchLivePhotos(in album:)`

Fetches Live Photos from a specific album.

```swift
func fetchLivePhotos(in album: AlbumItem) async -> [LivePhotoAsset]
```

**Parameters:**
- `album`: The album to fetch from

**Returns:** Array of `LivePhotoAsset` in the album

---

##### `fetchAlbums()`

Fetches all albums containing Live Photos.

```swift
nonisolated func fetchAlbums() -> [AlbumItem]
```

**Returns:** Array of `AlbumItem` with Live Photo counts

---

##### `requestThumbnail(for:targetSize:completion:)`

Requests a thumbnail image for a photo asset.

```swift
nonisolated func requestThumbnail(
    for asset: PHAsset,
    targetSize: CGSize,
    completion: @escaping @Sendable (NSImage?) -> Void
)
```

**Parameters:**
- `asset`: The photo asset
- `targetSize`: Desired thumbnail size in pixels
- `completion`: Callback with the loaded image

---

### ConversionService

Actor-based service for converting Live Photos to standard photos.

```swift
actor ConversionService {
    static let shared = ConversionService()
}
```

#### Methods

##### `convertLivePhotoToStandard(asset:)`

Converts a single Live Photo to a standard photo.

```swift
func convertLivePhotoToStandard(asset: PHAsset) async throws -> Int64
```

**Parameters:**
- `asset`: The Live Photo asset to convert

**Returns:** `Int64` — Bytes saved (video component size)

**Throws:** `ConversionError` on failure

**Notes:**
- Preserves all edits (Long Exposure, key frame selection)
- Preserves metadata (date, location, favorite status)
- Creates new standard photo and deletes original

---

##### `batchConvertWithSinglePrompt(assets:options:progressHandler:)`

Converts multiple Live Photos with minimal permission prompts.

```swift
func batchConvertWithSinglePrompt(
    assets: [LivePhotoAsset],
    options: ConversionOptions,
    progressHandler: @escaping @Sendable (Int, Int, Int64) -> Void
) async -> [ConversionResult]
```

**Parameters:**
- `assets`: Array of Live Photos to convert
- `options`: Conversion options (export settings)
- `progressHandler`: Called with (current, total, bytesSaved)

**Returns:** Array of `ConversionResult` for each asset

**Notes:**
- Only shows 2 permission prompts total (add + delete)
- Handles optional video/original export before conversion

---

##### `calculateVideoSize(for:)`

Calculates the video component size of a Live Photo.

```swift
func calculateVideoSize(for asset: PHAsset) async -> Int64
```

**Parameters:**
- `asset`: The Live Photo asset

**Returns:** `Int64` — Size of video component in bytes

---

##### `calculateAssetSizes(for:)`

Calculates both image and video sizes for an asset.

```swift
func calculateAssetSizes(for asset: PHAsset) async -> (imageSize: Int64, videoSize: Int64)
```

**Parameters:**
- `asset`: The Live Photo asset

**Returns:** Tuple with image and video sizes in bytes

---

### ExportService

Actor-based service for exporting photos and videos.

```swift
actor ExportService {
    static let shared = ExportService()
}
```

#### Methods

##### `exportVideoComponent(of:to:progressHandler:)`

Exports the video component of a Live Photo.

```swift
func exportVideoComponent(
    of asset: PHAsset,
    to destinationURL: URL,
    progressHandler: @escaping @Sendable (Double) -> Void
) async throws
```

**Parameters:**
- `asset`: The Live Photo asset
- `destinationURL`: Directory to save the video
- `progressHandler`: Called with progress (0.0 - 1.0)

**Throws:** `ExportError.noVideoComponent` if no video found

---

##### `exportOriginalLivePhoto(_:to:progressHandler:)`

Exports both image and video components of a Live Photo.

```swift
func exportOriginalLivePhoto(
    _ asset: PHAsset,
    to destinationURL: URL,
    progressHandler: @escaping @Sendable (Double) -> Void
) async throws
```

**Parameters:**
- `asset`: The Live Photo asset
- `destinationURL`: Directory to save files
- `progressHandler`: Called with progress (0.0 - 1.0)

---

## Models

### LivePhotoAsset

Represents a Live Photo with its metadata.

```swift
struct LivePhotoAsset: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    let creationDate: Date?
    var imageSize: Int64
    var videoSize: Int64
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique identifier (asset.localIdentifier) |
| `asset` | `PHAsset` | PhotoKit asset reference |
| `creationDate` | `Date?` | When photo was taken |
| `imageSize` | `Int64` | Image file size in bytes |
| `videoSize` | `Int64` | Video file size in bytes |

#### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `totalSize` | `Int64` | Sum of image and video sizes |
| `formattedVideoSize` | `String` | Human-readable video size |
| `formattedTotalSize` | `String` | Human-readable total size |

---

### AlbumItem

Represents a photo album containing Live Photos.

```swift
struct AlbumItem: Identifiable, Hashable {
    let id: String
    let title: String
    let collection: PHAssetCollection
    let livePhotoCount: Int
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique identifier |
| `title` | `String` | Album display name |
| `collection` | `PHAssetCollection` | PhotoKit collection |
| `livePhotoCount` | `Int` | Number of Live Photos |

---

### ConversionOptions

User-selected options for the conversion process.

```swift
struct ConversionOptions {
    var exportVideoBeforeConversion: Bool = false
    var exportOriginalBeforeConversion: Bool = false
    var videoExportURL: URL?
    var originalExportURL: URL?
}
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `exportVideoBeforeConversion` | `Bool` | `false` | Export .MOV before converting |
| `exportOriginalBeforeConversion` | `Bool` | `false` | Export original files before converting |
| `videoExportURL` | `URL?` | `nil` | Destination for video exports |
| `originalExportURL` | `URL?` | `nil` | Destination for original exports |

---

### ConversionState

Enum representing the current state of conversion.

```swift
enum ConversionState: Equatable {
    case idle
    case preparing
    case exporting(progress: Double, description: String)
    case converting(progress: Double, current: Int, total: Int)
    case completed(converted: Int, failed: Int, savedBytes: Int64)
    case failed(error: String)
}
```

#### Cases

| Case | Description |
|------|-------------|
| `idle` | No conversion in progress |
| `preparing` | Initializing conversion |
| `exporting` | Exporting files before conversion |
| `converting` | Converting Live Photos |
| `completed` | Conversion finished |
| `failed` | Conversion failed with error |

---

### ConversionResult

Result of converting a single Live Photo.

```swift
struct ConversionResult {
    let asset: LivePhotoAsset
    let success: Bool
    let savedBytes: Int64
    let error: Error?
}
```

---

## Errors

### ConversionError

```swift
enum ConversionError: LocalizedError {
    case noVideoComponent
    case noImageComponent
    case failedToReadImage
    case failedToWriteOutput
    case photoLibraryError(underlying: Error)
    case unknownError
}
```

### ExportError

```swift
enum ExportError: LocalizedError {
    case noVideoComponent
    case noImageComponent
    case exportFailed(underlying: Error)
}
```

---

## Usage Examples

### Fetching Live Photos

```swift
// Fetch all Live Photos
let photos = await PhotoKitService.shared.fetchAllLivePhotos()

// Fetch from specific album
let albumPhotos = await PhotoKitService.shared.fetchLivePhotos(in: album)
```

### Converting Photos

```swift
// Single conversion
let savedBytes = try await ConversionService.shared.convertLivePhotoToStandard(asset: photo.asset)

// Batch conversion
let options = ConversionOptions(
    exportVideoBeforeConversion: true,
    videoExportURL: videosFolder
)

let results = await ConversionService.shared.batchConvertWithSinglePrompt(
    assets: selectedPhotos,
    options: options
) { current, total, saved in
    print("Progress: \(current)/\(total), Saved: \(saved) bytes")
}
```

### Exporting Files

```swift
// Export video only
try await ExportService.shared.exportVideoComponent(
    of: asset,
    to: exportFolder
) { progress in
    print("Export progress: \(progress * 100)%")
}
```
