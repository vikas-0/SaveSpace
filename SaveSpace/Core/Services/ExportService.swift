import Foundation
import Photos

actor ExportService {
    static let shared = ExportService()
    
    private init() {}
    
    func exportVideoComponent(
        of asset: PHAsset,
        to destinationURL: URL,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws {
        let resources = PHAssetResource.assetResources(for: asset)
        
        guard let videoResource = resources.first(where: { resource in
            resource.type == .pairedVideo || resource.type == .fullSizePairedVideo
        }) else {
            throw ExportError.noVideoComponent
        }
        
        let fileName = videoResource.originalFilename
        let fileURL = destinationURL.appendingPathComponent(fileName)
        
        try FileManager.default.createDirectory(
            at: destinationURL,
            withIntermediateDirectories: true
        )
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress in
            Task { @MainActor in
                progressHandler(progress)
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHAssetResourceManager.default().writeData(
                for: videoResource,
                toFile: fileURL,
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
    
    func exportOriginalLivePhoto(
        _ asset: PHAsset,
        to destinationURL: URL,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws {
        let resources = PHAssetResource.assetResources(for: asset)
        
        try FileManager.default.createDirectory(
            at: destinationURL,
            withIntermediateDirectories: true
        )
        
        let imageResource = resources.first { $0.type == .photo || $0.type == .fullSizePhoto }
        let videoResource = resources.first { $0.type == .pairedVideo || $0.type == .fullSizePairedVideo }
        
        let totalResources = [imageResource, videoResource].compactMap { $0 }.count
        var completedResources = 0
        
        for resource in [imageResource, videoResource].compactMap({ $0 }) {
            let fileName = resource.originalFilename
            let fileURL = destinationURL.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            options.progressHandler = { progress in
                let baseProgress = Double(completedResources) / Double(totalResources)
                let resourceProgress = progress / Double(totalResources)
                Task { @MainActor in
                    progressHandler(baseProgress + resourceProgress)
                }
            }
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                PHAssetResourceManager.default().writeData(
                    for: resource,
                    toFile: fileURL,
                    options: options
                ) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            
            completedResources += 1
        }
    }
    
    func exportImageOnly(
        _ asset: PHAsset,
        to destinationURL: URL,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws {
        let resources = PHAssetResource.assetResources(for: asset)
        
        guard let imageResource = resources.first(where: { resource in
            resource.type == .photo || resource.type == .fullSizePhoto
        }) else {
            throw ExportError.noImageComponent
        }
        
        try FileManager.default.createDirectory(
            at: destinationURL,
            withIntermediateDirectories: true
        )
        
        let fileName = imageResource.originalFilename
        let fileURL = destinationURL.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress in
            Task { @MainActor in
                progressHandler(progress)
            }
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHAssetResourceManager.default().writeData(
                for: imageResource,
                toFile: fileURL,
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
}

enum ExportError: LocalizedError {
    case noVideoComponent
    case noImageComponent
    case exportFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .noVideoComponent:
            return "No video component found in Live Photo"
        case .noImageComponent:
            return "No image component found in Live Photo"
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        }
    }
}
