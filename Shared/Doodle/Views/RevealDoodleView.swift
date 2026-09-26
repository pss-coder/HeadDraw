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
                    // Button
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        
                        if let _ = drawing.thumbnailImage {
                            let imageUrl = shareImageRenderer()
                            ShareLink(
                                item: imageUrl,
                                preview: SharePreview("My HeadDraw doodle")
                            ) {
                                Label("Share doodle", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(SketchyButtonStyle(tone: .paper))
                        }
                        Button {
                            onNewDoodle(drawing)
                        } label: {
                            Label("Go again", systemImage: "plus")
                        }
                        .buttonStyle(SketchyButtonStyle(tone: .paper))
                    }
                    Button {
                        //TODO: pass the data
                        onDoodleSave(drawing)
                    } label: {
                        Label("Save to gallery", systemImage: "checkmark")
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
    }
    
    func shareImageRenderer() -> URL {
        let renderer = ImageRenderer(content: Image(uiImage: drawing.thumbnailImage!))
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("doodle.png")
        
        if let data = renderer.uiImage?.pngData() {
            try? data.write(to: tempURL)
        }
        return tempURL
    }
}

#Preview {
    RevealDoodleView(
        drawing: DrawingModel(drawingData: .init(), thumbnailData: .init())
    ,
    onNewDoodle: { _ in
        //
    } ,onDoodleSave: { _ in
        //
    })

}
