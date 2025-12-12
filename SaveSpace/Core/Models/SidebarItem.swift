import Foundation

enum SidebarItem: Hashable, Identifiable {
    case allLivePhotos
    case album(AlbumItem)
    case dateGroup(DateGroup)
    
    var id: String {
        switch self {
        case .allLivePhotos:
            return "all-live-photos"
        case .album(let album):
            return "album-\(album.id)"
        case .dateGroup(let group):
            return "date-\(group.id)"
        }
    }
    
    var title: String {
        switch self {
        case .allLivePhotos:
            return "All Live Photos"
        case .album(let album):
            return album.title
        case .dateGroup(let group):
            return group.title
        }
    }
    
    var icon: String {
        switch self {
        case .allLivePhotos:
            return "livephoto"
        case .album(let album):
            return album.icon
        case .dateGroup(let group):
            return group.icon
        }
    }
}
