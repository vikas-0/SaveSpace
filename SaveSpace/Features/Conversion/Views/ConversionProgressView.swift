import SwiftUI

struct ConversionProgressView: View {
    let state: ConversionState
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            stateIcon
            stateMessage
            progressIndicator
            actionButton
        }
        .padding(32)
        .frame(width: 400)
    }
    
    @ViewBuilder
    private var stateIcon: some View {
        switch state {
        case .idle:
            EmptyView()
            
        case .preparing:
            ProgressView()
                .controlSize(.large)
            
        case .exporting:
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
        case .converting:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.accent)
                .symbolEffect(.rotate)
            
        case .completed(let converted, let failed, _):
            if failed == 0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
            } else if converted == 0 {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
            }
            
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
        }
    }
    
    @ViewBuilder
    private var stateMessage: some View {
        switch state {
        case .idle:
            EmptyView()
            
        case .preparing:
            Text("Preparing...")
                .font(.title2)
                .fontWeight(.medium)
            
        case .exporting(_, let description):
            VStack(spacing: 4) {
                Text("Exporting Files")
                    .font(.title2)
                    .fontWeight(.medium)
                Text(description)
                    .foregroundStyle(.secondary)
            }
            
        case .converting(_, let current, let total):
            VStack(spacing: 4) {
                Text("Converting Photos")
                    .font(.title2)
                    .fontWeight(.medium)
                Text("Processing \(current) of \(total)")
                    .foregroundStyle(.secondary)
            }
            
        case .completed(let converted, let failed, let savedBytes):
            VStack(spacing: 8) {
                Text("Conversion Complete")
                    .font(.title2)
                    .fontWeight(.medium)
                
                HStack(spacing: 16) {
                    VStack {
                        Text("\(converted)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        Text("Converted")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if failed > 0 {
                        VStack {
                            Text("\(failed)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                            Text("Failed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    VStack {
                        Text(savedBytes.formattedFileSize)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        Text("Saved")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
        case .failed(let error):
            VStack(spacing: 4) {
                Text("Conversion Failed")
                    .font(.title2)
                    .fontWeight(.medium)
                Text(error)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    @ViewBuilder
    private var progressIndicator: some View {
        switch state {
        case .idle, .completed, .failed:
            EmptyView()
            
        case .preparing:
            ProgressView()
                .progressViewStyle(.linear)
                .frame(maxWidth: .infinity)
            
        case .exporting(let progress, _), .converting(let progress, _, _):
            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: .infinity)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch state {
        case .completed, .failed:
            Button("Done") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            
        default:
            EmptyView()
        }
    }
}

struct ConversionProgressOverlay: View {
    @EnvironmentObject var viewModel: PhotoLibraryViewModel
    
    var body: some View {
        Group {
            if viewModel.conversionState != .idle {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    ConversionProgressView(state: viewModel.conversionState) {
                        viewModel.resetConversionState()
                    }
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 20)
                }
            }
        }
        .animation(.easeInOut, value: viewModel.conversionState != .idle)
    }
}

#Preview("Preparing") {
    ConversionProgressView(state: .preparing, onDismiss: {})
}

#Preview("Exporting") {
    ConversionProgressView(
        state: .exporting(progress: 0.45, description: "Exporting 5 of 10"),
        onDismiss: {}
    )
}

#Preview("Converting") {
    ConversionProgressView(
        state: .converting(progress: 0.7, current: 7, total: 10),
        onDismiss: {}
    )
}

#Preview("Completed") {
    ConversionProgressView(
        state: .completed(converted: 10, failed: 0, savedBytes: 156_000_000),
        onDismiss: {}
    )
}

#Preview("Failed") {
    ConversionProgressView(
        state: .failed(error: "Permission denied"),
        onDismiss: {}
    )
}
