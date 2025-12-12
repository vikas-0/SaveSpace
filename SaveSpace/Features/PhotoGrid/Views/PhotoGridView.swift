import SwiftUI
import Photos

struct PhotoGridView: View {
    let sidebarItem: SidebarItem?
    @EnvironmentObject var viewModel: PhotoLibraryViewModel
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 8)
    ]
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.livePhotos.isEmpty {
                emptyView
            } else {
                gridView
            }
        }
        .onChange(of: sidebarItem) { _, newItem in
            Task {
                await viewModel.loadPhotos(for: newItem)
            }
        }
        .task {
            if viewModel.livePhotos.isEmpty {
                await viewModel.loadPhotos(for: sidebarItem)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading Live Photos...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "livephoto.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Live Photos")
                .font(.title2)
                .fontWeight(.medium)
            Text("No Live Photos found in this location")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var gridView: some View {
        VStack(spacing: 0) {
            if let savings = viewModel.estimatedSavings, !viewModel.selectedPhotos.isEmpty {
                savingsBanner(savings)
            }
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.livePhotos) { photo in
                        PhotoThumbnailView(
                            photo: photo,
                            isSelected: viewModel.isSelected(photo)
                        ) {
                            viewModel.toggleSelection(for: photo)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func savingsBanner(_ savings: SpaceSavingsEstimate) -> some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(.green)
            
            Text("Estimated savings: ")
                .foregroundStyle(.secondary)
            
            Text(savings.formattedEstimatedSavings)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
            
            Text("(\(savings.formattedSavingsPercentage) of \(savings.formattedCurrentSize))")
                .foregroundStyle(.secondary)
                .font(.caption)
            
            Spacer()
            
            Text("\(viewModel.selectedPhotos.count) photos selected")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    PhotoGridView(sidebarItem: .allLivePhotos)
        .environmentObject(PhotoLibraryViewModel())
}
