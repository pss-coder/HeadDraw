import SwiftUI

struct SupportedAirPodsModelsList: View {
    @Environment(\.colorScheme) private var colorScheme

    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 12) {
            Label("Works best with", systemImage: "checkmark.seal.fill")
                .font(compact ? SketchyTheme.Font.body(14, weight: .semibold) : SketchyTheme.Font.heading(22))
                .foregroundStyle(SketchyTheme.Color.teal)

            VStack(spacing: compact ? 3 : 0) {
                ForEach(AirpodsMotionService.supportedModels, id: \.self) { model in
                    HStack(spacing: 10) {
                        Image(systemName: symbol(for: model))
                            .font(.system(size: compact ? 13 : 17, weight: .medium))
                            .foregroundStyle(SketchyTheme.Color.coral)
                            .frame(width: compact ? 20 : 28)
                            .accessibilityHidden(true)

                        Text(model)
                            .font(SketchyTheme.Font.body(compact ? 12 : 16, weight: .medium))
                            .foregroundStyle(SketchyTheme.Color.ink(for: colorScheme))

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, compact ? 1 : 9)

                    if !compact && model != AirpodsMotionService.supportedModels.last {
                        Rectangle()
                            .fill(SketchyTheme.Color.mustard.opacity(0.28))
                            .frame(height: 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func symbol(for model: String) -> String {
        if model.contains("Pro") { return "airpodspro" }
        if model.contains("Max") { return "airpodsmax" }
        if model.contains("3rd") { return "airpods.gen3" }
        return "headphones"
    }
}

struct SupportedAirPodsModelsSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                SupportedAirPodsModelsList()
                    .padding(24)
            }
            .background(SketchyTheme.Color.paper(for: colorScheme))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(SketchyTheme.Font.body(16, weight: .semibold))
                        .tint(SketchyTheme.Color.teal)
                }
            }
            .navigationTitle("Supported models")
        }
        .foregroundStyle(SketchyTheme.Color.ink(for: colorScheme))
        .tint(SketchyTheme.Color.teal)
    }
}