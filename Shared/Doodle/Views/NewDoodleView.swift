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
    @Environment(\.colorScheme) private var colorScheme
    @State private var timeRemaining: TimeInterval = 15
    @State private var hasFinished = false
    
    @Binding var airpodsService: AirpodsMotionService
    @Binding var blinkDetector: BlinkDetector
    
    @State private var newDrawing: PKDrawing = PKDrawing()
    
    @State private var airPodsStrokes: [PKStroke] = []
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
                    .colorInvert()
                    .colorMultiply(SketchyTheme.Color.teal)
                    .shadow(color: SketchyTheme.Color.teal.opacity(0.42), radius: 5)
                    .onChange(of: airpodsService.cursorPosition) { oldValue, newValue in
                        guard blinkDetector.wasBothEyesClosed else { return }
                        
                        let position = CGPoint(
                            x: newValue.x * proxy.size.width,
                            y: newValue.y * proxy.size.height
                        )
                        
                        drawingPoints.append(position)
                        
                        if drawingPoints.count >= 2 {
                            let currentStroke = makeAirPodsStroke(from: drawingPoints)
                            
                            newDrawing = PKDrawing(
                                strokes: airPodsStrokes + [currentStroke]
                            )
                        }
                    }
                    .onChange(of: blinkDetector.wasBothEyesClosed) { wasClosed, isClosed in
                        if !wasClosed && isClosed {
                            SketchyFeedback.lightHaptic()
                        }

                            // Eyes just opened
                        if wasClosed && !isClosed {
                            guard drawingPoints.count >= 2 else {
                                drawingPoints.removeAll()
                                return
                            }
                            
                            let stroke = makeAirPodsStroke(from: drawingPoints)
                            
                            airPodsStrokes.append(stroke)
                            drawingPoints.removeAll()
                            
                            newDrawing = PKDrawing(strokes: airPodsStrokes)
                        }
                    }
                    
                    Circle()
                        .fill(SketchyTheme.Color.coral)
                        .frame(width: 12, height: 12)
                        .shadow(color: SketchyTheme.Color.coral.opacity(0.85), radius: 9)
                        .position(
                            x: airpodsService.cursorPosition.x * proxy.size.width,
                            y: airpodsService.cursorPosition.y * proxy.size.height
                        )
                }
                .background(SketchyTheme.Color.canvas)
                .overlay {
                    Rectangle()
                        .stroke(SketchyTheme.Color.teal.opacity(0.55), lineWidth: 1.5)
                }
                .padding()
            }
            statusInfo
        }
        .sketchyPaper()
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
                if timeRemaining <= 3 {
                    SketchyFeedback.countdownCue()
                }
            }
            if timeRemaining <= 0 {
                hasFinished = true
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
                Text("Blink to ink")
            } icon: {
                Image(systemName: "eye")
            }
            .font(SketchyTheme.Font.body(15, weight: .semibold))
            Spacer()
            HStack {
                Text(formatTime(timeRemaining))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SketchyTheme.Color.coral)
            }
        }
        .padding(.horizontal, SketchyTheme.Spacing.medium)
        .padding(.vertical, SketchyTheme.Spacing.large)
        .sketchyBorder(
            color: SketchyTheme.Color.ink(for: colorScheme).opacity(0.72),
            fill: SketchyTheme.Color.paperShade(for: colorScheme)
        )
        .padding(.horizontal)
    }
    
    private var prompt: some View {
        VStack {
            Text("Doodle dare: a cat")
                .font(SketchyTheme.Font.heading(21))
            Text("Aim for cat-ish.")
                .font(SketchyTheme.Font.body(14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SketchyTheme.Spacing.medium)
        .sketchyBorder(
            color: SketchyTheme.Color.ink(for: colorScheme).opacity(0.72),
            fill: SketchyTheme.Color.paperShade(for: colorScheme)
        )
        .padding(.horizontal)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = max(0, Int(time))
        return String(format: "00:%02d", seconds)
    }
    
    private func makeAirPodsStroke(
        from points: [CGPoint]
    ) -> PKStroke {
        
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
        
        return PKStroke(
            ink: PKInk(
                .pen,
                color: .black
            ),
            path: path
        )
    }
}

//#Preview {
//    NewDoodleView(onDoodleCompleted: {drawing in})
//}
