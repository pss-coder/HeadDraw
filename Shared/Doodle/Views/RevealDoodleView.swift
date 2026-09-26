//
//  RevealDoodleView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 26/9/26.
//
// A sheet to view the completed doodle
import SwiftUI

struct RevealDoodleView: View {
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
                    Text("Your doodle is ready!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.bottom, 10)
                }
                
                // image
                if let image = UIImage(data: drawing.thumbnailData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 350)
                        .border(.primary)
                }
                    // Button
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        
                        if let _ = drawing.thumbnailImage {
                            let imageUrl = shareImageRenderer()
                            ShareLink(
                                item: imageUrl,
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
                        Button {
                            onNewDoodle(drawing)
                        } label: {
                            Label("New Doodle", systemImage: "plus")
                        }
                        .buttonStyle(
                            MinimalButtonStyle(
                                backgroundColor: .clear,
                                foregroundColor: .primary,
                                borderColor: Color.primary.opacity(0.2)
                            )
                        )
                    }
                    Button {
                        //TODO: pass the data
                        onDoodleSave(drawing)
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    .buttonStyle(
                        MinimalButtonStyle(
                            backgroundColor: .primary,
                            foregroundColor: Color(.systemBackground),
                            borderColor: .primary
                        )
                    )
                }
                .padding()
            }
            .padding()
            
            // Confetti
            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false) // Allows tapping buttons underneath
        }
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
