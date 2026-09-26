//
//  CanvasView.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 19/9/26.
//
import PencilKit
import SwiftUI

struct CanvasView: UIViewRepresentable {
    
    let drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        
        let canvasView = PKCanvasView()
        
        canvasView.isUserInteractionEnabled = false
        canvasView.backgroundColor = .clear // TODO: Some dotted metal background ??
        
        return canvasView
    }
    
    func updateUIView(
        _ uiView: PKCanvasView,
        context: Context
    ) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }
}

extension PKDrawing {
    var isEmpty: Bool {
        return self.strokes.isEmpty
    }
}
