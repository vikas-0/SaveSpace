import Foundation

struct ConversionOptions {
    var mode: ConversionMode = .replaceOriginal
    var exportVideoBeforeConversion: Bool = false
    var exportOriginalBeforeConversion: Bool = false
    var videoExportURL: URL?
    var originalExportURL: URL?
    
    enum ConversionMode {
        case replaceOriginal
        case keepOriginalCreateCopy
        
        var description: String {
            switch self {
            case .replaceOriginal:
                return "Replace original (preserve metadata)"
            case .keepOriginalCreateCopy:
                return "Keep original, create standard copy"
            }
        }
    }
    
    static var `default`: ConversionOptions {
        ConversionOptions()
    }
}

enum ConversionState: Equatable {
    case idle
    case preparing
    case exporting(progress: Double, description: String)
    case converting(progress: Double, current: Int, total: Int)
    case completed(converted: Int, failed: Int, savedBytes: Int64)
    case failed(error: String)
    
    var isProcessing: Bool {
        switch self {
        case .idle, .completed, .failed:
            return false
        case .preparing, .exporting, .converting:
            return true
        }
    }
    
    var progress: Double {
        switch self {
        case .idle:
            return 0
        case .preparing:
            return 0
        case .exporting(let progress, _):
            return progress * 0.3
        case .converting(let progress, _, _):
            return 0.3 + (progress * 0.7)
        case .completed:
            return 1.0
        case .failed:
            return 0
        }
    }
}

struct ConversionResult {
    let asset: LivePhotoAsset
    let success: Bool
    let savedBytes: Int64
    let error: Error?
}
