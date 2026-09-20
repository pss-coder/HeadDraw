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
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        
        // can draw using hand/apple pencil
        canvasView.drawingPolicy = .anyInput
        // Show pencil tools
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        //canvasView.drawing = drawing
        canvasView.delegate = context.coordinator
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // update UI
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }
    
    static func dismantleUIView(
        _ uiView: PKCanvasView,
        coordinator: Coordinator
    ) {
        // clear the drawing
        uiView.drawing = PKDrawing()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }
}

extension CanvasView {
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var drawing: Binding<PKDrawing>
        
        init(drawing: Binding<PKDrawing>) {
            self.drawing = drawing
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            self.drawing.wrappedValue = canvasView.drawing
        }
    }
}

#Preview {
    @Previewable @State var drawing: PKDrawing = PKDrawing()
    VStack {
        HStack {
            Button {
                    // Clears the canvas
                drawing = PKDrawing()
            } label: {
                Text("Clear all")
            }
            
            Spacer()
            
            Button {
                    // get drawing data representation
                    //drawing.dataRepresentation()
                    // image
                    //drawing.image(from: .drawing(drawing), scale: 1.0)
            } label: {
                Text("Save")
            }
        }
        .padding()
        
        Divider()
        
        CanvasView(drawing: $drawing)
        
    }
}
