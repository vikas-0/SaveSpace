import Foundation
import Photos
import AppKit

actor ConversionService {
    static let shared = ConversionService()
    
    private init() {}
    
    /// Converts a Live Photo to a standard photo by:
    /// 1. Exporting the RENDERED still image (preserves Long Exposure, key frame, edits)
    /// 2. Deleting the original Live Photo
    /// 3. Creating a new standard photo from the exported image
    func convertLivePhotoToStandard(asset: PHAsset) async throws -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        
        // Find video resource to calculate savings
        guard let videoResource = resources.first(where: { resource in
            resource.type == .pairedVideo || resource.type == .fullSizePairedVideo
        }) else {
            throw ConversionError.noVideoComponent
        }
        
        let videoSize = getResourceSize(for: videoResource)
        
        // Create temp directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SaveSpace-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Export the RENDERED image (preserves edits like Long Exposure, key frame selection)
        let imageURL = tempDir.appendingPathComponent("converted_\(asset.localIdentifier.replacingOccurrences(of: "/", with: "_")).heic")
        try await exportRenderedImage(asset: asset, to: imageURL)
        
        // Store original metadata
        let creationDate = asset.creationDate
        let location = asset.location
        let isFavorite = asset.isFavorite
        
        // Delete original Live Photo and create new standard photo
        try await deleteAndReplace(
            originalAsset: asset,
            withImageAt: imageURL,
            creationDate: creationDate,
            location: location,
            isFavorite: isFavorite
        )
        
        return videoSize
    }
    
    /// Exports the rendered/edited version of the image (preserves Long Exposure, key frame, etc.)
    private func exportRenderedImage(asset: PHAsset, to url: URL) async throws {
        let options = PHImageRequestOptions()
        options.version = .current  // Gets the edited/rendered version
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        let imageManager = PHImageManager.default()
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            imageManager.requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, dataUTI, orientation, info in
                guard let imageData = data else {
                    let error = info?[PHImageErrorKey] as? Error ?? ConversionError.failedToReadImage
                    continuation.resume(throwing: error)
                    return
                }
                
                do {
                    // Write the rendered image data to file
                    try imageData.write(to: url)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func exportResource(_ resource: PHAssetResource, to url: URL) async throws {
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHAssetResourceManager.default().writeData(
                for: resource,
                toFile: url,
                options: options
            ) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func deleteAndReplace(
        originalAsset: PHAsset,
        withImageAt imageURL: URL,
        creationDate: Date?,
        location: CLLocation?,
        isFavorite: Bool
    ) async throws {
        // First, create the new photo
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, fileURL: imageURL, options: nil)
                
                // Preserve metadata
                if let date = creationDate {
                    creationRequest.creationDate = date
                }
                if let loc = location {
                    creationRequest.location = loc
                }
                creationRequest.isFavorite = isFavorite
                
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: ConversionError.unknownError)
                }
            }
        }
        
        // Then delete the original
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets([originalAsset] as NSFastEnumeration)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: ConversionError.unknownError)
                }
            }
        }
    }
    
    nonisolated func getResourceSize(for resource: PHAssetResource) -> Int64 {
        if let size = resource.value(forKey: "fileSize") as? Int64 {
            return size
        }
        return 0
    }
    
    /// Calculate actual video size for an asset
    func calculateVideoSize(for asset: PHAsset) async -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        
        guard let videoResource = resources.first(where: { resource in
            resource.type == .pairedVideo || resource.type == .fullSizePairedVideo
        }) else {
            return 0
        }
        
        return getResourceSize(for: videoResource)
    }
    
    /// Calculate both image and video sizes for an asset
    func calculateAssetSizes(for asset: PHAsset) async -> (imageSize: Int64, videoSize: Int64) {
        let resources = PHAssetResource.assetResources(for: asset)
        
        let imageResource = resources.first(where: { resource in
            resource.type == .photo || resource.type == .fullSizePhoto
        })
        
        let videoResource = resources.first(where: { resource in
            resource.type == .pairedVideo || resource.type == .fullSizePairedVideo
        })
        
        let imgSize = imageResource.map { getResourceSize(for: $0) } ?? 0
        let vidSize = videoResource.map { getResourceSize(for: $0) } ?? 0
        
        return (imgSize, vidSize)
    }
    
    /// Batch convert multiple Live Photos with only 2 permission prompts total
    /// (one for creating new photos, one for deleting originals)
    func batchConvertWithSinglePrompt(
        assets: [LivePhotoAsset],
        options: ConversionOptions,
        progressHandler: @escaping (Int, Int, Int64) -> Void
    ) async -> [ConversionResult] {
        var results: [ConversionResult] = []
        var totalSaved: Int64 = 0
        
        // Create temp directory for all exports
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SaveSpace-batch-\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        } catch {
            return assets.map { ConversionResult(asset: $0, success: false, savedBytes: 0, error: error) }
        }
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Structure to hold export info
        struct ExportInfo {
            let asset: LivePhotoAsset
            let imageURL: URL
            let videoSize: Int64
            let creationDate: Date?
            let location: CLLocation?
            let isFavorite: Bool
        }
        
        var exportedPhotos: [ExportInfo] = []
        var failedAssets: [(LivePhotoAsset, Error)] = []
        
        // Phase 1: Export all photos and run optional exports
        for (index, livePhoto) in assets.enumerated() {
            progressHandler(index, assets.count, totalSaved)
            
            do {
                // Optional video export
                if options.exportVideoBeforeConversion, let exportURL = options.videoExportURL {
                    try await ExportService.shared.exportVideoComponent(
                        of: livePhoto.asset,
                        to: exportURL
                    ) { _ in }
                }
                
                // Optional original export
                if options.exportOriginalBeforeConversion, let exportURL = options.originalExportURL {
                    try await ExportService.shared.exportOriginalLivePhoto(
                        livePhoto.asset,
                        to: exportURL
                    ) { _ in }
                }
                
                // Calculate video size
                let videoSize = await calculateVideoSize(for: livePhoto.asset)
                
                // Export rendered image
                let safeFilename = livePhoto.asset.localIdentifier
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: ":", with: "_")
                let imageURL = tempDir.appendingPathComponent("photo_\(safeFilename).heic")
                try await exportRenderedImage(asset: livePhoto.asset, to: imageURL)
                
                exportedPhotos.append(ExportInfo(
                    asset: livePhoto,
                    imageURL: imageURL,
                    videoSize: videoSize,
                    creationDate: livePhoto.asset.creationDate,
                    location: livePhoto.asset.location,
                    isFavorite: livePhoto.asset.isFavorite
                ))
                
            } catch {
                failedAssets.append((livePhoto, error))
            }
        }
        
        // Add failed exports to results
        for (asset, error) in failedAssets {
            results.append(ConversionResult(asset: asset, success: false, savedBytes: 0, error: error))
        }
        
        guard !exportedPhotos.isEmpty else {
            return results
        }
        
        // Phase 2: Create all new photos in ONE batch operation (single prompt)
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                PHPhotoLibrary.shared().performChanges {
                    for info in exportedPhotos {
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, fileURL: info.imageURL, options: nil)
                        
                        if let date = info.creationDate {
                            creationRequest.creationDate = date
                        }
                        if let loc = info.location {
                            creationRequest.location = loc
                        }
                        creationRequest.isFavorite = info.isFavorite
                    }
                } completionHandler: { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? ConversionError.unknownError)
                    }
                }
            }
        } catch {
            // All creations failed
            for info in exportedPhotos {
                results.append(ConversionResult(asset: info.asset, success: false, savedBytes: 0, error: error))
            }
            return results
        }
        
        // Phase 3: Delete all originals in ONE batch operation (single prompt)
        let assetsToDelete = exportedPhotos.map { $0.asset.asset }
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
                } completionHandler: { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? ConversionError.unknownError)
                    }
                }
            }
            
            // All succeeded
            for info in exportedPhotos {
                totalSaved += info.videoSize
                results.append(ConversionResult(
                    asset: info.asset,
                    success: true,
                    savedBytes: info.videoSize,
                    error: nil
                ))
            }
            
        } catch {
            // Deletion failed - photos were created but originals not deleted
            for info in exportedPhotos {
                results.append(ConversionResult(
                    asset: info.asset,
                    success: false,
                    savedBytes: 0,
                    error: ConversionError.photoLibraryError(underlying: error)
                ))
            }
        }
        
        progressHandler(assets.count, assets.count, totalSaved)
        return results
    }
}

enum ConversionError: LocalizedError {
    case noVideoComponent
    case noImageComponent
    case failedToReadImage
    case failedToWriteOutput
    case photoLibraryError(underlying: Error)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .noVideoComponent:
            return "No video component found in Live Photo"
        case .noImageComponent:
            return "No image component found in Live Photo"
        case .failedToReadImage:
            return "Failed to read image data"
        case .failedToWriteOutput:
            return "Failed to write converted image"
        case .photoLibraryError(let error):
            return "Photo library error: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
