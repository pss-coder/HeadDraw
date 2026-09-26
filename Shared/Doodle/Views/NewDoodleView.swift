//
//  NewDoodleView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 26/9/26.
//

import SwiftUI
import Combine
import PencilKit

struct NewDoodleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var timeRemaining: TimeInterval = 15
    @State private var hasFinished = false
    
    @Binding var airpodsService: AirpodsMotionService
    @Binding var blinkDetector: BlinkDetector
    
    @State private var newDrawing: PKDrawing = PKDrawing()
    @State private var drawingPoints: [CGPoint] = []
    
    @State var isTouching: Bool = false
    
    let onDoodleCompleted: (DrawingModel) -> Void

    private let timer = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        VStack {
            prompt
            
            // AirpodsCanvas
            GeometryReader { proxy in
                ZStack {
                    CanvasView(
                        drawing: newDrawing,
                    )
                    .onChange(of: airpodsService.cursorPosition) { oldValue, newValue in
                        // we draw points on to the canvas
                        // we append only if eyes was closed
                        guard blinkDetector.wasBothEyesClosed else { return }
                        
                        let position = CGPoint(x: airpodsService.cursorPosition.x * proxy.size.width,
                                               y: airpodsService.cursorPosition.y * proxy.size.height)
                        
                        // pass the new position of the cursor over to canvas drawing points to draw 
                        drawingPoints.append(position)
                        
                        //canvasView receives the latest drawing and renders it.
                        newDrawing = makeAirPodsDrawing(
                            from: drawingPoints
                        )
                    }
                    
                    Circle()
                        .fill(.blue)
                        .frame(width: 12, height: 12)
                        .position(
                            x: airpodsService.cursorPosition.x * proxy.size.width,
                            y: airpodsService.cursorPosition.y * proxy.size.height
                        )
                }
                .border(.primary)
                .padding()
            }
            statusInfo
        }
        .onDisappear(perform: {
            blinkDetector.stop()
            airpodsService.stopDeviceMotionUpdates()
        })
        .toolbar(content: {
            ToolbarItem(placement: .destructiveAction) {
                Button {
                    //TODO: Stop
                    dismiss()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .foregroundStyle(Color.red)

            }
        })
        .onReceive(timer) { _ in
            guard !hasFinished else { return }

            if timeRemaining > 0 {
                timeRemaining -= 1
            }
            if timeRemaining <= 0 {
                hasFinished = true
                //TODO: Pass the data data
                let data = newDrawing.dataRepresentation()
                
                let thumbnail = newDrawing.image(
                    from: newDrawing.bounds,
                    scale: 1
                )
                
                guard let thumbnailData = thumbnail.pngData() else {
                    return
                }
                
                let drawingModel = DrawingModel(
                    drawingData: data,
                    thumbnailData: thumbnailData
                )
                
                onDoodleCompleted(drawingModel)
            }
        }
    }
    
    private var statusInfo: some View {
        HStack {
            Label {
                Text("Status")
            } icon: {
                Image(systemName: "eye")
            }
            Spacer()
            HStack {
                Text(formatTime(timeRemaining))
                    .font(.system(.subheadline, design: .monospaced))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 24) // Vertical spacing inside the card
        .padding(.horizontal)
    }
    
    private var prompt: some View {
        VStack {
            Text("Doodle: Cat")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16) // Vertical spacing inside the card
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    Color(.gray).opacity(0.3)
                ) // Adapts to Dark Mode automatically
        )
        .padding(.horizontal) // Spacing outside the card from screen edges
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = max(0, Int(time))
        return String(format: "00:%02d", seconds)
    }
    
    private func makeAirPodsDrawing(
        from points: [CGPoint]
    ) -> PKDrawing {
        
        guard points.count >= 2 else {
            return PKDrawing()
        }
        
        let strokePoints = points.enumerated().map {
            PKStrokePoint(
                location: $0.element,
                timeOffset: TimeInterval($0.offset) * 0.01,
                size: CGSize(width: 5, height: 5),
                opacity: 1,
                force: 1,
                azimuth: 0,
                altitude: .pi / 2
            )
        }
        
        let path = PKStrokePath(
            controlPoints: strokePoints,
            creationDate: Date()
        )
        
        let stroke = PKStroke(
            ink: PKInk(
                .pen,
                color: .black
            ),
            path: path
        )
        
        return PKDrawing(
            strokes: [stroke]
        )
    }
}

//#Preview {
//    NewDoodleView(onDoodleCompleted: {drawing in})
//}
