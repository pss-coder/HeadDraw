//
//  HomeView.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 19/9/26.
//

import SwiftUI
import PencilKit
import SwiftData

struct HomeView: View {
    @State private var newDrawing: PKDrawing = PKDrawing()
//    CanvasView.generateDottedCircleDrawing(
//        center: CGPoint(x: 200, y: 300),
//        radius: 100,
//        dotCount: 30,
//        dotSize: 6.0
//    )
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        sort: \DrawingModel.createdAt,
        order: .reverse
    )
    
    private var drawings: [DrawingModel]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Gallery")
                    .font(.title)
                    .fontWeight(.bold)
                NavigationLink {
                    CanvasView(drawing: $newDrawing) { drawing in
                        saveDrawing(drawing)
                    }
                } label: {
                    HStack {
                        Image(systemName: "pencil.line")
                        Text("Start Drawing")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .buttonSizing(.flexible)
                .buttonBorderShape(.roundedRectangle(radius: 8))

                
                // Have a list here
//                List {
//                    
//                    NavigationLink("Drawing 1") {
//                        
//                        Text("Drawing 1 Detail")
//                        
//                    }
//                    
//                    NavigationLink("Drawing 2") {
//                        
//                        Text("Drawing 2 Detail")
//                        
//                    }
//                    
//                    NavigationLink("Drawing 3") {
//                        
//                        Text("Drawing 3 Detail")
//                        
//                    }
//                    
//                }
                List(drawings) { drawing in
                    HStack {
                        if let image = UIImage(data: drawing.thumbnailData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(
                                drawing.createdAt,
                                style: .date
                            )
                            Text(
                                drawing.createdAt,
                                style: .time
                            )
                        }
                        
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: .infinity)
            }
            .padding()
        }
    }
    
    private func saveDrawing(_ drawing: PKDrawing) {
        let data = drawing.dataRepresentation()
        
        let thumbnail = drawing.image(
            from: drawing.bounds,
            scale: 1
        )
        
        guard let thumbnailData = thumbnail.pngData() else {
            return
        }
        
        let drawingModel = DrawingModel(
            drawingData: data,
            thumbnailData: thumbnailData
        )
        
        modelContext.insert(drawingModel)
        
        do {
            try modelContext.save()
            debugPrint("drawing saved")
        } catch {
            print("Failed to save drawing:", error)
        }
    }
}

#Preview {
    HomeView()
}
