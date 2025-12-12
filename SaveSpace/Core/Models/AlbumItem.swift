import Foundation
import Photos

struct AlbumItem: Identifiable, Hashable {
    let id: String
    let title: String
    let collection: PHAssetCollection
    let livePhotoCount: Int
    let icon: String
    
    init(collection: PHAssetCollection, livePhotoCount: Int) {
        self.id = collection.localIdentifier
        self.title = collection.localizedTitle ?? "Untitled Album"
        self.collection = collection
        self.livePhotoCount = livePhotoCount
        self.icon = AlbumItem.iconForAlbumType(collection.assetCollectionSubtype)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AlbumItem, rhs: AlbumItem) -> Bool {
        lhs.id == rhs.id
    }
    
    private static func iconForAlbumType(_ subtype: PHAssetCollectionSubtype) -> String {
        switch subtype {
        case .smartAlbumFavorites:
            return "heart.fill"
        case .smartAlbumRecentlyAdded:
            return "clock.fill"
        case .smartAlbumSelfPortraits:
            return "person.crop.square.fill"
        case .smartAlbumScreenshots:
            return "camera.viewfinder"
        case .smartAlbumLivePhotos:
            return "livephoto"
        case .albumRegular:
            return "photo.on.rectangle"
        default:
            return "folder.fill"
        }
    }
}

struct DateGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let year: Int
    let month: Int?
    
    var icon: String {
        "calendar"
    }
    
    init(year: Int, month: Int? = nil) {
        self.year = year
        self.month = month
        
        if let month = month {
            self.id = "\(year)-\(month)"
            let dateComponents = DateComponents(year: year, month: month)
            let calendar = Calendar.current
            if let date = calendar.date(from: dateComponents) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                self.title = formatter.string(from: date)
            } else {
                self.title = "\(month)/\(year)"
            }
        } else {
            self.id = "\(year)"
            self.title = "\(year)"
        }
    }
}
