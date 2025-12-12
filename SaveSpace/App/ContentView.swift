import SwiftUI
import Photos

struct ContentView: View {
    @EnvironmentObject var viewModel: PhotoLibraryViewModel
    @State private var selectedSidebarItem: SidebarItem? = .allLivePhotos
    @State private var showingConversionSheet = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        Group {
            switch viewModel.authorizationStatus {
            case .notDetermined:
                PermissionRequestView {
                    viewModel.requestAuthorization()
                }
            case .authorized, .limited:
                mainContent
            case .denied, .restricted:
                PermissionDeniedView()
            @unknown default:
                PermissionRequestView {
                    viewModel.requestAuthorization()
                }
            }
        }
        .onAppear {
            viewModel.checkAuthorizationStatus()
        }
    }
    
    private var mainContent: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedItem: $selectedSidebarItem)
                .environmentObject(viewModel)
        } detail: {
            PhotoGridView(sidebarItem: selectedSidebarItem)
                .environmentObject(viewModel)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        toolbarItems
                    }
                }
        }
        .navigationTitle("SaveSpace")
        .sheet(isPresented: $showingConversionSheet) {
            ConversionOptionsSheet(
                selectedPhotos: viewModel.selectedPhotos,
                onConvert: { options in
                    Task {
                        await viewModel.convertSelectedPhotos(with: options)
                    }
                }
            )
            .environmentObject(viewModel)
        }
    }
    
    @ViewBuilder
    private var toolbarItems: some View {
        if !viewModel.selectedPhotos.isEmpty {
            Text("\(viewModel.selectedPhotos.count) selected")
                .foregroundStyle(.secondary)
            
            Button {
                viewModel.clearSelection()
            } label: {
                Text("Clear")
            }
            
            Button {
                showingConversionSheet = true
            } label: {
                Label("Convert", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
        }
        
        Button {
            viewModel.selectAll()
        } label: {
            Label("Select All", systemImage: "checkmark.circle")
        }
        .disabled(viewModel.livePhotos.isEmpty)
        
        Button {
            Task {
                await viewModel.refreshPhotos()
            }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
    }
}

struct PermissionRequestView: View {
    let onRequest: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Photos Access Required")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("SaveSpace needs access to your Photos library to find and convert Live Photos.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 400)
            
            Button("Grant Access") {
                onRequest()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            
            Text("Photos Access Denied")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Please grant Photos access in System Settings to use SaveSpace.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 400)
            
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingsView: View {
    @AppStorage("defaultExportPath") private var defaultExportPath: String = ""
    @AppStorage("preserveOriginalDate") private var preserveOriginalDate: Bool = true
    
    var body: some View {
        Form {
            Section("Export") {
                HStack {
                    TextField("Default Export Path", text: $defaultExportPath)
                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            defaultExportPath = url.path
                        }
                    }
                }
            }
            
            Section("Conversion") {
                Toggle("Preserve original creation date", isOn: $preserveOriginalDate)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 200)
        .navigationTitle("Settings")
    }
}

#Preview {
    ContentView()
        .environmentObject(PhotoLibraryViewModel())
}
