import Foundation
@preconcurrency import Photos
import SwiftUI
import Combine

@MainActor
class PhotoLibraryViewModel: NSObject, ObservableObject {
    @Published var livePhotos: [LivePhotoAsset] = []
    @Published var selectedPhotos: Set<LivePhotoAsset> = []
    @Published var isLoading = false
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var conversionState: ConversionState = .idle
    @Published var estimatedSavings: SpaceSavingsEstimate?
    @Published var searchText = ""
    
    private let photoKitService = PhotoKitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupObservers()
    }
    
    private func setupObservers() {
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func checkAuthorizationStatus() {
        Task {
            authorizationStatus = await photoKitService.checkAuthorizationStatus()
            if authorizationStatus == .authorized || authorizationStatus == .limited {
                await loadAllPhotos()
            }
        }
    }
    
    func requestAuthorization() {
        Task {
            authorizationStatus = await photoKitService.requestAuthorization()
            if authorizationStatus == .authorized || authorizationStatus == .limited {
                await loadAllPhotos()
            }
        }
    }
    
    func loadAllPhotos() async {
        isLoading = true
        livePhotos = await photoKitService.fetchAllLivePhotos()
        await calculateSizesForVisiblePhotos()
        isLoading = false
    }
    
    func loadPhotos(for sidebarItem: SidebarItem?) async {
        guard let item = sidebarItem else {
            await loadAllPhotos()
            return
        }
        
        isLoading = true
        selectedPhotos.removeAll()
        
        switch item {
        case .allLivePhotos:
            livePhotos = await photoKitService.fetchAllLivePhotos()
            
        case .album(let album):
            livePhotos = await photoKitService.fetchLivePhotos(in: album.collection)
            
        case .dateGroup(let group):
            livePhotos = await photoKitService.fetchLivePhotos(forYear: group.year, month: group.month)
        }
        
        await calculateSizesForVisiblePhotos()
        isLoading = false
    }
    
    func refreshPhotos() async {
        await loadAllPhotos()
    }
    
    private func calculateSizesForVisiblePhotos() async {
        var updatedPhotos: [LivePhotoAsset] = []
        
        for photo in livePhotos.prefix(50) {
            let updated = await photoKitService.calculateAssetSizes(for: photo)
            updatedPhotos.append(updated)
        }
        
        for photo in livePhotos.dropFirst(50) {
            updatedPhotos.append(photo)
        }
        
        livePhotos = updatedPhotos
        updateEstimatedSavings()
    }
    
    func toggleSelection(for photo: LivePhotoAsset) {
        if selectedPhotos.contains(photo) {
            selectedPhotos.remove(photo)
        } else {
            selectedPhotos.insert(photo)
        }
        updateEstimatedSavings()
    }
    
    func selectAll() {
        selectedPhotos = Set(livePhotos)
        updateEstimatedSavings()
    }
    
    func clearSelection() {
        selectedPhotos.removeAll()
        updateEstimatedSavings()
    }
    
    func isSelected(_ photo: LivePhotoAsset) -> Bool {
        selectedPhotos.contains(photo)
    }
    
    private func updateEstimatedSavings() {
        if selectedPhotos.isEmpty {
            estimatedSavings = nil
        } else {
            let selectedArray = Array(selectedPhotos)
            let knownSizes = selectedArray.filter { $0.videoSize > 0 }
            
            if knownSizes.isEmpty {
                let estimate = SpaceCalculator.estimateSavingsForUnknownSizes(photoCount: selectedPhotos.count)
                estimatedSavings = SpaceSavingsEstimate(
                    currentSize: estimate * 2,
                    estimatedSavings: estimate,
                    photoCount: selectedPhotos.count
                )
            } else {
                estimatedSavings = SpaceCalculator.estimateSavings(for: selectedArray)
            }
        }
    }
    
    func convertSelectedPhotos(with options: ConversionOptions) async {
        guard !selectedPhotos.isEmpty else { return }
        
        conversionState = .preparing
        
        let photosToConvert = Array(selectedPhotos)
        
        // Use batch conversion with single permission prompts
        conversionState = .converting(progress: 0, current: 0, total: photosToConvert.count)
        
        let results = await ConversionService.shared.batchConvertWithSinglePrompt(
            assets: photosToConvert,
            options: options
        ) { current, total, saved in
            Task { @MainActor in
                let progress = Double(current) / Double(total)
                self.conversionState = .converting(progress: progress, current: current, total: total)
            }
        }
        
        let convertedCount = results.filter { $0.success }.count
        let failedCount = results.filter { !$0.success }.count
        let totalSaved = results.reduce(0) { $0 + $1.savedBytes }
        
        conversionState = .completed(converted: convertedCount, failed: failedCount, savedBytes: totalSaved)
        
        selectedPhotos.removeAll()
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        await loadAllPhotos()
    }
    
    func resetConversionState() {
        conversionState = .idle
    }
}

extension PhotoLibraryViewModel: PHPhotoLibraryChangeObserver {
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor [weak self] in
            await self?.loadAllPhotos()
        }
    }
}
