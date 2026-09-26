//
//  DoodleDetailView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 26/9/26.
//
// Saved Doodles
import SwiftUI

struct DoodleDetailView: View {
    let drawing: DrawingModel
    @State private var shareURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Your doodle")
                    .font(.title)
                    .fontWeight(.bold)

                if let image = drawing.thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 350)
                        .border(.primary)
                }

                Text(drawing.createdAt, format: .dateTime.month(.wide).day().year())
                    .foregroundStyle(.secondary)

                if let shareURL {
                    ShareLink(
                        item: shareURL,
                        preview: SharePreview("My Doodle")
                    ) {
                        Label("Share Image", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(
                        MinimalButtonStyle(
                            backgroundColor: .clear,
                            foregroundColor: .primary,
                            borderColor: Color.primary.opacity(0.2)
                        )
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Doodle")
        .navigationBarTitleDisplayMode(.inline)
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
        drawing: DrawingModel(drawingData: .init(), thumbnailData: .init())
    )
}
