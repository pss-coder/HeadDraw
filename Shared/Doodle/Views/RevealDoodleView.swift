//
//  RevealDoodleView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 26/9/26.
//
// A sheet to view the completed doodle
import SwiftUI

struct RevealDoodleView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isRestartPromptPresented = false

    let drawing: DrawingModel
    // new doodle <- basically clear everything, and restart again
    let onNewDoodle: (DrawingModel) -> Void
    // save doodle
    let onDoodleSave: (DrawingModel) -> Void
    
    var body: some View {
        ZStack {
            VStack {
                    // Prompt
                HStack {
                    Text("A masterpiece-ish!")
                        .font(SketchyTheme.Font.heading(30))
                        .foregroundStyle(SketchyTheme.Color.ink(for: colorScheme))
                        .padding(.bottom, 10)
                }
                
                // image
                if let image = UIImage(data: drawing.thumbnailData) {
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
                    // Button
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        if let _ = drawing.thumbnailImage {
                            let imageUrl = shareImageRenderer()
                            ShareLink(
                                item: imageUrl,
                                preview: SharePreview("My HeadDrawing")
                            ) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(SketchyButtonStyle(tone: .paper))
                        }
                        Button {
                            isRestartPromptPresented = true
                        } label: {
                            Label("Go again", systemImage: "plus")
                        }
                        .buttonStyle(SketchyButtonStyle(tone: .paper))
                    }
                    Button {
                        onDoodleSave(drawing)
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    .buttonStyle(SketchyButtonStyle())
                }
                .padding()
            }
            .padding()
            
            // Confetti
            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false) // Allows tapping buttons underneath
        }
        .sketchyPaper()
        .confirmationDialog(
            "Save this doodle before starting another?",
            isPresented: $isRestartPromptPresented,
            titleVisibility: .visible
        ) {
            Button("Save and Go Again") {
                onDoodleSave(drawing)
                onNewDoodle(drawing)
            }
            Button("Skip Saving") {
                onNewDoodle(drawing)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    func shareImageRenderer() -> URL {
        let renderer = ImageRenderer(content: Image(uiImage: drawing.thumbnailImage!))
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("HeadDraw.png")
        
        if let data = renderer.uiImage?.pngData() {
            try? data.write(to: tempURL)
        }
        return tempURL
    }
}

#Preview {
    RevealDoodleView(
        drawing: DrawingModel(
            drawingData: .init(),
            thumbnailData: .init(),
            prompt: "",
            drawingMode: .game
        )
    ,
    onNewDoodle: { _ in
        //
    } ,
onDoodleSave: { _ in
        //
    })

}
