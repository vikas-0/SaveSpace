import SwiftUI
@preconcurrency import Photos

struct PhotoThumbnailView: View {
    let photo: LivePhotoAsset
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var thumbnail: NSImage?
    @State private var isHovering = false
    @State private var imageSize: Int64 = 0
    @State private var videoSize: Int64 = 0
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailImage
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                }
                .overlay(alignment: .bottomLeading) {
                    photoInfo
                }
                .shadow(color: .black.opacity(0.2), radius: isHovering ? 8 : 4)
            
            selectionIndicator
        }
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onTap()
        }
        .task {
            await loadThumbnail()
        }
    }
    
    @ViewBuilder
    private var thumbnailImage: some View {
        if let thumbnail = thumbnail {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    ProgressView()
                        .controlSize(.small)
                }
        }
    }
    
    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accentColor : Color.black.opacity(0.5))
                .frame(width: 24, height: 24)
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(8)
    }
    
    private var displayVideoSize: Int64 {
        videoSize > 0 ? videoSize : photo.videoSize
    }
    
    private var displayImageSize: Int64 {
        imageSize > 0 ? imageSize : photo.imageSize
    }
    
    private var totalSize: Int64 {
        displayImageSize + displayVideoSize
    }
    
    private var photoInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "livephoto")
                    .font(.caption2)
                
                if totalSize > 0 {
                    Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                        .font(.caption2)
                }
            }
            
            // Show video size that can be saved
            if displayVideoSize > 0 {
                Text("Video: \(ByteCountFormatter.string(fromByteCount: displayVideoSize, countStyle: .file))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(6)
    }
    
    private func loadThumbnail() async {
        let targetSize = CGSize(width: 300, height: 300)
        
        // Load thumbnail
        PhotoKitService.shared.requestThumbnail(
            for: photo.asset,
            targetSize: targetSize
        ) { image in
            Task { @MainActor in
                self.thumbnail = image
            }
        }
        
        // Load both image and video sizes
        let sizes = await ConversionService.shared.calculateAssetSizes(for: photo.asset)
        self.imageSize = sizes.imageSize
        self.videoSize = sizes.videoSize
    }
}

#Preview {
    PhotoThumbnailView(
        photo: LivePhotoAsset(
            asset: PHAsset(),
            imageSize: 2_500_000,
            videoSize: 3_500_000
        ),
        isSelected: false,
        onTap: {}
    )
    .frame(width: 200, height: 200)
}
