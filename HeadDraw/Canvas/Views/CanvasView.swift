//
//  CanvasView.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 19/9/26.
//
import PencilKit
import SwiftUI

struct CanvasView: UIViewRepresentable {
    
    let toolPicker = PKToolPicker()
    
    @Binding var drawing: PKDrawing
    @Binding var airpodsDrawingPoints: [CGPoint]
    @Binding var cursorPosition: CGPoint
    @Binding var isTouching: Bool // to denote if pencil can be drawn
    
    let onDrawingFinished: (PKDrawing) -> Void
    
    func makeUIView(context: Context) -> PKTrackingCanvasView {
        let canvasView = PKTrackingCanvasView()
        
        // can draw using hand/apple pencil
        canvasView.drawingPolicy = .anyInput
        // Show pencil tools
//        toolPicker.setVisible(true, forFirstResponder: canvasView)
//        toolPicker.addObserver(canvasView)
//        canvasView.becomeFirstResponder()
        
        //canvasView.drawing = drawing
        canvasView.delegate = context.coordinator
        
        // drawing callbacks on touches
        canvasView.onTouchBegan = { position in
            cursorPosition = position
            //isTouching = true
        }
        
        canvasView.onTouchMoved = { position in
            cursorPosition = position
        }
        
        canvasView.onTouchEnded = {
            //isTouching = false
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKTrackingCanvasView, context: Context) {
        // update UI
        // we handle the drawing here
//        if uiView.drawing != drawing {
//            // uiView.drawing = drawing
//        }
        let points = airpodsDrawingPoints.map {
            PKStrokePoint(
                location: $0,
                timeOffset: 0,
                size: CGSize(width: 5, height: 5),
                opacity: 1,
                force: 1,
                azimuth: 0,
                altitude: .pi / 2
            )
        }
        
        let path = PKStrokePath(
            controlPoints: points,
            creationDate: Date()
        )
        
        let stroke = PKStroke(
            ink: PKInk(.pen, color: .black),
            path: path
        )
        
        uiView.drawing = PKDrawing(strokes: [stroke])
        print("strokes count: \(uiView.drawing.strokes.count)")
    }
    
    static func dismantleUIView(
        _ uiView: PKTrackingCanvasView,
        coordinator: Coordinator
    ) {
        debugPrint("cleanig up")
        if (!uiView.drawing.isEmpty) {
                // send over
            coordinator.onDrawingFinished(uiView.drawing)
        }
        // clear the drawing
        uiView.drawing = PKDrawing()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing, onDrawingFinished: onDrawingFinished)
    }
}

extension CanvasView {
    
    
    static func generateDottedCircleDrawing(center: CGPoint, radius: CGFloat, dotCount: Int = 40, dotSize: CGFloat = 8.0) -> PKDrawing {
        var strokes: [PKStroke] = []
        
            // Explicitly define ink properties (.pen or .marker work best)
        let ink = PKInk(.pen, color: .systemBlue)
        
        for i in 0..<dotCount {
            let angle = (CGFloat(i) / CGFloat(dotCount)) * 2.0 * .pi
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            let startPointLocation = CGPoint(x: x, y: y)
                // FIX 1: Shift the endpoint by 0.1 points so PencilKit detects a valid vector path length
            let endPointLocation = CGPoint(x: x + 0.1, y: y + 0.1)
            
            let firstPoint = PKStrokePoint(
                location: startPointLocation,
                timeOffset: 0,
                size: CGSize(width: dotSize, height: dotSize),
                opacity: 1.0,
                force: 1.0,
                azimuth: 0.0,
                altitude: .pi / 2
            )
            
            let secondPoint = PKStrokePoint(
                location: endPointLocation,
                timeOffset: 0.01,
                size: CGSize(width: dotSize, height: dotSize),
                opacity: 1.0,
                force: 1.0,
                azimuth: 0.0,
                altitude: .pi / 2
            )
            
                // Bundle the micro-segment together
            let path = PKStrokePath(controlPoints: [firstPoint, secondPoint], creationDate: Date())
            
                // FIX 2: Explicitly pass an identity matrix transformation and an empty mask structure
            let stroke = PKStroke(
                ink: ink,
                path: path,
                transform: .identity,
                mask: nil
            )
            strokes.append(stroke)
        }
        
        return PKDrawing(strokes: strokes)
    }


}

extension CanvasView {
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var drawing: Binding<PKDrawing>
        let onDrawingFinished: (PKDrawing) -> Void
        
        init(drawing: Binding<PKDrawing>, onDrawingFinished: @escaping (PKDrawing) -> Void) {
            self.drawing = drawing
            self.onDrawingFinished = onDrawingFinished
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            self.drawing.wrappedValue = canvasView.drawing
        }
    }
}

//#Preview {
//    @Previewable @State var drawing: PKDrawing = CanvasView.generateDottedCircleDrawing(
//        center: CGPoint(x: 200, y: 300),
//        radius: 100,
//        dotCount: 30,
//        dotSize: 6.0
//    )
//    
//    VStack {
//        HStack {
//            Button {
//                    // Clears the canvas
//                drawing = PKDrawing()
//            } label: {
//                Text("Clear all")
//            }
//            
//            Spacer()
//            
//            Button {
//                    // get drawing data representation
//                    //drawing.dataRepresentation()
//                    // image
//                    //drawing.image(from: .drawing(drawing), scale: 1.0)
//            } label: {
//                Text("Save")
//            }
//        }
//        .padding()
//        
//        Divider()
//        
//        CanvasView(drawing: $drawing) { drawing in
//            debugPrint(drawing.strokes.count)
//        }
//        
//    }
//}


//import PencilKit
//import UIKit

extension PKDrawing {
    var isEmpty: Bool {
        return self.strokes.isEmpty
    }
}
