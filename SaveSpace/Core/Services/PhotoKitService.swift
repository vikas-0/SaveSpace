import Foundation
@preconcurrency import Photos
@preconcurrency import AppKit

actor PhotoKitService {
    static let shared = PhotoKitService()
    
    private let imageManager = PHCachingImageManager()
    private var cachedAssets: [String: LivePhotoAsset] = [:]
    
    private init() {
        imageManager.allowsCachingHighQualityImages = true
    }
    
    func checkAuthorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    
    func fetchAllLivePhotos() async -> [LivePhotoAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(
            format: "(mediaSubtype & %d) != 0",
            PHAssetMediaSubtype.photoLive.rawValue
        )
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var livePhotos: [LivePhotoAsset] = []
        results.enumerateObjects { asset, _, _ in
            let livePhoto = LivePhotoAsset(asset: asset)
            livePhotos.append(livePhoto)
        }
        
        return livePhotos
    }
    
    func fetchLivePhotos(in collection: PHAssetCollection) async -> [LivePhotoAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(
            format: "(mediaSubtype & %d) != 0",
            PHAssetMediaSubtype.photoLive.rawValue
        )
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        let results = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        
        var livePhotos: [LivePhotoAsset] = []
        results.enumerateObjects { asset, _, _ in
            let livePhoto = LivePhotoAsset(asset: asset)
            livePhotos.append(livePhoto)
        }
        
        return livePhotos
    }
    
    func fetchLivePhotos(forYear year: Int, month: Int? = nil) async -> [LivePhotoAsset] {
        let calendar = Calendar.current
        
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = month ?? 1
        startComponents.day = 1
        
        var endComponents = DateComponents()
        if let month = month {
            endComponents.year = year
            endComponents.month = month + 1
            endComponents.day = 1
        } else {
            endComponents.year = year + 1
            endComponents.month = 1
            endComponents.day = 1
        }
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return []
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(
            format: "(mediaSubtype & %d) != 0 AND creationDate >= %@ AND creationDate < %@",
            PHAssetMediaSubtype.photoLive.rawValue,
            startDate as NSDate,
            endDate as NSDate
        )
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var livePhotos: [LivePhotoAsset] = []
        results.enumerateObjects { asset, _, _ in
            let livePhoto = LivePhotoAsset(asset: asset)
            livePhotos.append(livePhoto)
        }
        
        return livePhotos
    }
    
    func fetchAlbums() async -> [AlbumItem] {
        var albums: [AlbumItem] = []
        
        let smartAlbumTypes: [PHAssetCollectionSubtype] = [
            .smartAlbumFavorites,
            .smartAlbumRecentlyAdded,
            .smartAlbumSelfPortraits
        ]
        
        for subtype in smartAlbumTypes {
            let collections = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum,
                subtype: subtype,
                options: nil
            )
            
            collections.enumerateObjects { collection, _, _ in
                let count = self.countLivePhotos(in: collection)
                if count > 0 {
                    let album = AlbumItem(collection: collection, livePhotoCount: count)
                    albums.append(album)
                }
            }
        }
        
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: nil
        )
        
        userAlbums.enumerateObjects { collection, _, _ in
            let count = self.countLivePhotos(in: collection)
            if count > 0 {
                let album = AlbumItem(collection: collection, livePhotoCount: count)
                albums.append(album)
            }
        }
        
        return albums
    }
    
    func fetchDateGroups() async -> [DateGroup] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(
            format: "(mediaSubtype & %d) != 0",
            PHAssetMediaSubtype.photoLive.rawValue
        )
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var dateSet: Set<String> = []
        var dateGroups: [DateGroup] = []
        let calendar = Calendar.current
        
        results.enumerateObjects { asset, _, _ in
            guard let date = asset.creationDate else { return }
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let year = components.year, let month = components.month else { return }
            
            let key = "\(year)-\(month)"
            if !dateSet.contains(key) {
                dateSet.insert(key)
                dateGroups.append(DateGroup(year: year, month: month))
            }
        }
        
        return dateGroups.sorted { first, second in
            if first.year != second.year {
                return first.year > second.year
            }
            return (first.month ?? 0) > (second.month ?? 0)
        }
    }
    
    private nonisolated func countLivePhotos(in collection: PHAssetCollection) -> Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(
            format: "(mediaSubtype & %d) != 0",
            PHAssetMediaSubtype.photoLive.rawValue
        )
        
        let results = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        return results.count
    }
    
    func requestThumbnail(
        for asset: PHAsset,
        targetSize: CGSize
    ) async -> NSImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // Only return when we have the final image (not degraded)
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }
    
    func getAssetResources(for asset: PHAsset) async -> (imageResource: PHAssetResource?, videoResource: PHAssetResource?) {
        let resources = PHAssetResource.assetResources(for: asset)
        
        let imageResource = resources.first { resource in
            resource.type == .photo || resource.type == .fullSizePhoto
        }
        
        let videoResource = resources.first { resource in
            resource.type == .pairedVideo || resource.type == .fullSizePairedVideo
        }
        
        return (imageResource, videoResource)
    }
    
    func getResourceSize(for resource: PHAssetResource) async -> Int64 {
        if let size = resource.value(forKey: "fileSize") as? Int64 {
            return size
        }
        return 0
    }
    
    func calculateAssetSizes(for asset: LivePhotoAsset) async -> LivePhotoAsset {
        let (imageResource, videoResource) = await getAssetResources(for: asset.asset)
        
        var imageSize: Int64 = 0
        var videoSize: Int64 = 0
        
        if let imageRes = imageResource {
            imageSize = await getResourceSize(for: imageRes)
        }
        
        if let videoRes = videoResource {
            videoSize = await getResourceSize(for: videoRes)
        }
        
        return LivePhotoAsset(
            asset: asset.asset,
            imageSize: imageSize,
            videoSize: videoSize
        )
    }
    
    func getTotalLivePhotoCount() async -> Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(
            format: "(mediaSubtype & %d) != 0",
            PHAssetMediaSubtype.photoLive.rawValue
        )
        
        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        return results.count
    }
}
