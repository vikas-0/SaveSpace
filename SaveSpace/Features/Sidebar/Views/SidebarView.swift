import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    @EnvironmentObject var viewModel: PhotoLibraryViewModel
    @StateObject private var sidebarViewModel = SidebarViewModel()
    
    var body: some View {
        List(selection: $selectedItem) {
            Section("Library") {
                Label {
                    HStack {
                        Text("All Live Photos")
                        Spacer()
                        Text("\(sidebarViewModel.totalLivePhotoCount)")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } icon: {
                    Image(systemName: "livephoto")
                }
                .tag(SidebarItem.allLivePhotos)
            }
            
            if !sidebarViewModel.albums.isEmpty {
                Section("Albums") {
                    ForEach(sidebarViewModel.albums) { album in
                        Label {
                            HStack {
                                Text(album.title)
                                Spacer()
                                Text("\(album.livePhotoCount)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        } icon: {
                            Image(systemName: album.icon)
                        }
                        .tag(SidebarItem.album(album))
                    }
                }
            }
            
            if !sidebarViewModel.dateGroups.isEmpty {
                Section("By Date") {
                    ForEach(sidebarViewModel.dateGroups) { group in
                        Label {
                            Text(group.title)
                        } icon: {
                            Image(systemName: group.icon)
                        }
                        .tag(SidebarItem.dateGroup(group))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        .task {
            await sidebarViewModel.loadSidebarData()
        }
        .refreshable {
            await sidebarViewModel.refresh()
        }
        .overlay {
            if sidebarViewModel.isLoading {
                ProgressView()
            }
        }
    }
}

#Preview {
    SidebarView(selectedItem: .constant(.allLivePhotos))
        .environmentObject(PhotoLibraryViewModel())
}
