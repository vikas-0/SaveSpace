import Foundation
import Photos

struct LivePhotoAsset: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    let creationDate: Date?
    let imageSize: Int64
    let videoSize: Int64
    
    var totalSize: Int64 {
        imageSize + videoSize
    }
    
    var potentialSavings: Int64 {
        videoSize
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedVideoSize: String {
        ByteCountFormatter.string(fromByteCount: videoSize, countStyle: .file)
    }
    
    var formattedPotentialSavings: String {
        ByteCountFormatter.string(fromByteCount: potentialSavings, countStyle: .file)
    }
    
    init(asset: PHAsset, imageSize: Int64 = 0, videoSize: Int64 = 0) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.creationDate = asset.creationDate
        self.imageSize = imageSize
        self.videoSize = videoSize
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LivePhotoAsset, rhs: LivePhotoAsset) -> Bool {
        lhs.id == rhs.id
    }
}

extension LivePhotoAsset {
    var monthYearString: String {
        guard let date = creationDate else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    var yearString: String {
        guard let date = creationDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}
