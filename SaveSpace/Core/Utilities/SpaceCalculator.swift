import Foundation

struct SpaceCalculator {
    static func calculateTotalSavings(for assets: [LivePhotoAsset]) -> Int64 {
        assets.reduce(0) { $0 + $1.potentialSavings }
    }
    
    static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    static func estimateSavings(for assets: [LivePhotoAsset]) -> SpaceSavingsEstimate {
        let totalVideoSize = assets.reduce(0) { $0 + $1.videoSize }
        let totalImageSize = assets.reduce(0) { $0 + $1.imageSize }
        let totalCurrentSize = totalVideoSize + totalImageSize
        
        return SpaceSavingsEstimate(
            currentSize: totalCurrentSize,
            estimatedSavings: totalVideoSize,
            photoCount: assets.count
        )
    }
    
    static func averageVideoSize(for assets: [LivePhotoAsset]) -> Int64 {
        guard !assets.isEmpty else { return 0 }
        let total = assets.reduce(0) { $0 + $1.videoSize }
        return total / Int64(assets.count)
    }
    
    static func estimateSavingsForUnknownSizes(photoCount: Int) -> Int64 {
        let averageVideoSize: Int64 = 3_500_000
        return Int64(photoCount) * averageVideoSize
    }
}

struct SpaceSavingsEstimate {
    let currentSize: Int64
    let estimatedSavings: Int64
    let photoCount: Int
    
    var formattedCurrentSize: String {
        ByteCountFormatter.string(fromByteCount: currentSize, countStyle: .file)
    }
    
    var formattedEstimatedSavings: String {
        ByteCountFormatter.string(fromByteCount: estimatedSavings, countStyle: .file)
    }
    
    var savingsPercentage: Double {
        guard currentSize > 0 else { return 0 }
        return Double(estimatedSavings) / Double(currentSize) * 100
    }
    
    var formattedSavingsPercentage: String {
        String(format: "%.1f%%", savingsPercentage)
    }
}
