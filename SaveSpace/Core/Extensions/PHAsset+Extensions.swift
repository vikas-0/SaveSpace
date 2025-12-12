import Foundation
import Photos

extension PHAsset {
    var isLivePhoto: Bool {
        mediaSubtypes.contains(.photoLive)
    }
    
    var formattedCreationDate: String {
        guard let date = creationDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDimensions: String {
        "\(pixelWidth) × \(pixelHeight)"
    }
}

extension PHAssetMediaSubtype {
    var description: String {
        var types: [String] = []
        
        if contains(.photoLive) {
            types.append("Live Photo")
        }
        if contains(.photoHDR) {
            types.append("HDR")
        }
        if contains(.photoScreenshot) {
            types.append("Screenshot")
        }
        if contains(.photoDepthEffect) {
            types.append("Depth Effect")
        }
        
        return types.isEmpty ? "Photo" : types.joined(separator: ", ")
    }
}

extension PHAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .limited:
            return "Limited"
        @unknown default:
            return "Unknown"
        }
    }
}
