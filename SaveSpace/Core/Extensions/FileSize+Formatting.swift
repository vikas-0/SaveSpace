import Foundation

extension Int64 {
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
    
    var formattedFileSizeShort: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: self)
    }
}

extension Int {
    var formattedFileSize: String {
        Int64(self).formattedFileSize
    }
}

extension Double {
    var formattedPercentage: String {
        String(format: "%.1f%%", self)
    }
}
