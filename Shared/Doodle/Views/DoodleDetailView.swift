//
//  DoodleDetailView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 26/9/26.
//
// Saved Doodles
import SwiftUI

struct DoodleDetailView: View {
    @Environment(\.colorScheme) private var colorScheme

    let drawing: DrawingModel
    @State private var shareURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Your Drawing")
                    .font(SketchyTheme.Font.heading(28))

                if let image = drawing.thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 350)
                        .padding(8)
                        .sketchyBorder(
                            color: SketchyTheme.Color.ink(for: colorScheme),
                            fill: SketchyTheme.Color.paperShade(for: colorScheme)
                        )
                }

                Text(drawing.createdAt, format: .dateTime.month(.wide).day().year())
                    .foregroundStyle(.secondary)

                Label(
                    drawing.drawingMode.title,
                    systemImage: drawing.drawingMode == .free ? "scribble.variable" : "timer"
                )
                .font(SketchyTheme.Font.body(16, weight: .semibold))
                .foregroundStyle(SketchyTheme.Color.teal)

                if drawing.drawingMode == .game, !drawing.prompt.isEmpty {
                    Text("Prompt: \(drawing.prompt)")
                        .font(SketchyTheme.Font.body(15))
                        .foregroundStyle(.secondary)
                }

                if let shareURL {
                    ShareLink(
                        item: shareURL,
                        preview: SharePreview("My HeadDraw doodle")
                    ) {
                        Label("Share doodle", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(SketchyButtonStyle(tone: .paper))
                }
            }
            .padding()
        }
        .sketchyPaper()
        .navigationTitle("Doodle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SketchyTheme.Color.paper(for: colorScheme), for: .navigationBar)
        .onAppear {
            shareURL = makeShareURL()
        }
    }

    private func makeShareURL() -> URL? {
        guard let image = drawing.thumbnailImage else { return nil }

        let renderer = ImageRenderer(content: Image(uiImage: image))
        guard let data = renderer.uiImage?.pngData() else { return nil }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("doodle-\(drawing.id.uuidString).png")

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

#Preview {
    DoodleDetailView(
        drawing: DrawingModel(
            drawingData: .init(),
            thumbnailData: .init(),
            prompt: "",
            drawingMode: .game
        )
    )
}
