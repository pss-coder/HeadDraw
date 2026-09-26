//
//  CanvasView.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 19/9/26.
//

import PencilKit
import SwiftUI

struct CanvasView: View {
    let drawing: PKDrawing
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.976, blue: 0.953)
                .colorEffect(ShaderLibrary.default.dottedPaper())
            
#if os(iOS)
            PencilDrawingView(drawing: drawing)
#elseif os(macOS)
            GeometryReader { proxy in
                if !drawing.strokes.isEmpty {
                    let canvasRect = CGRect(origin: .zero, size: proxy.size)
                    Image(platformImage: drawing.image(from: canvasRect, scale: 2.0))
                        .resizable()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
#endif
        }
    }
}

    // ─── PLATFORM DEPENDENT VIEW WRAPPER ────────────────────────────────────────

#if os(iOS)
private struct PencilDrawingView: UIViewRepresentable {
    let drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
            // Correct implementation for read-only viewer on iOS
        canvasView.isUserInteractionEnabled = false
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }
}
#endif


extension PKDrawing {
    var isEmpty: Bool {
        return self.strokes.isEmpty
    }
}
