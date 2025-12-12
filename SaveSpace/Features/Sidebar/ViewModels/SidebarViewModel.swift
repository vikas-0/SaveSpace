import Foundation
import Photos
import Combine

@MainActor
class SidebarViewModel: ObservableObject {
    @Published var albums: [AlbumItem] = []
    @Published var dateGroups: [DateGroup] = []
    @Published var isLoading = false
    @Published var totalLivePhotoCount = 0
    
    private let photoKitService = PhotoKitService.shared
    
    func loadSidebarData() async {
        isLoading = true
        
        async let albumsTask = photoKitService.fetchAlbums()
        async let dateGroupsTask = photoKitService.fetchDateGroups()
        async let countTask = photoKitService.getTotalLivePhotoCount()
        
        let (fetchedAlbums, fetchedDateGroups, count) = await (albumsTask, dateGroupsTask, countTask)
        
        albums = fetchedAlbums
        dateGroups = fetchedDateGroups
        totalLivePhotoCount = count
        isLoading = false
    }
    
    func refresh() async {
        await loadSidebarData()
    }
}
