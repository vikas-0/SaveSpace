import SwiftUI

struct ConversionOptionsSheet: View {
    let selectedPhotos: Set<LivePhotoAsset>
    let onConvert: (ConversionOptions) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: PhotoLibraryViewModel
    
    @State private var options = ConversionOptions.default
    @State private var videoExportPath: String = ""
    @State private var originalExportPath: String = ""
    
    private var estimatedSavings: SpaceSavingsEstimate {
        SpaceCalculator.estimateSavings(for: Array(selectedPhotos))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    conversionModeSection
                    exportOptionsSection
                    savingsEstimateSection
                }
                .padding(24)
            }
            
            Divider()
            
            footer
        }
        .frame(width: 500, height: 520)
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 32))
                .foregroundStyle(.accent)
            
            Text("Convert \(selectedPhotos.count) Live Photos")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Remove video components while preserving image quality and metadata")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
    
    private var conversionModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conversion Mode")
                .font(.headline)
            
            VStack(spacing: 8) {
                ConversionModeRow(
                    title: "Replace original",
                    subtitle: "Preserve all metadata, remove video component only",
                    isSelected: options.mode == .replaceOriginal,
                    icon: "arrow.triangle.swap"
                ) {
                    options.mode = .replaceOriginal
                }
                
                ConversionModeRow(
                    title: "Keep original, create copy",
                    subtitle: "Original Live Photo remains, standard copy is created",
                    isSelected: options.mode == .keepOriginalCreateCopy,
                    icon: "doc.on.doc"
                ) {
                    options.mode = .keepOriginalCreateCopy
                }
            }
        }
    }
    
    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Options")
                .font(.headline)
            
            VStack(spacing: 12) {
                Toggle(isOn: $options.exportVideoBeforeConversion) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export video clips before converting")
                        Text("Save .MOV files to a folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if options.exportVideoBeforeConversion {
                    PathPickerRow(
                        path: $videoExportPath,
                        placeholder: "Select folder for video exports..."
                    ) { url in
                        options.videoExportURL = url
                    }
                    .padding(.leading, 20)
                }
                
                Toggle(isOn: $options.exportOriginalBeforeConversion) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export original Live Photos")
                        Text("Save original HEIC + MOV pairs to a folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if options.exportOriginalBeforeConversion {
                    PathPickerRow(
                        path: $originalExportPath,
                        placeholder: "Select folder for originals..."
                    ) { url in
                        options.originalExportURL = url
                    }
                    .padding(.leading, 20)
                }
            }
        }
    }
    
    private var savingsEstimateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Space Savings Estimate")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current size")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(estimatedSavings.formattedCurrentSize)
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Estimated savings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(estimatedSavings.formattedEstimatedSavings)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var footer: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button("Convert") {
                onConvert(options)
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
        }
        .padding(16)
    }
    
    private var isValid: Bool {
        if options.exportVideoBeforeConversion && options.videoExportURL == nil {
            return false
        }
        if options.exportOriginalBeforeConversion && options.originalExportURL == nil {
            return false
        }
        return true
    }
}

struct ConversionModeRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .accent : .secondary)
                
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct PathPickerRow: View {
    @Binding var path: String
    let placeholder: String
    let onSelect: (URL) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)
            
            if path.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.secondary)
            } else {
                Text(path)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            Button("Browse...") {
                selectFolder()
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        
        if panel.runModal() == .OK, let url = panel.url {
            path = url.path
            onSelect(url)
        }
    }
}

#Preview {
    ConversionOptionsSheet(
        selectedPhotos: [],
        onConvert: { _ in }
    )
    .environmentObject(PhotoLibraryViewModel())
}
