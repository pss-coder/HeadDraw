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
    @State private var isPaused = false
    @State private var isPauseDialogPresented = false
    
    @Binding var airpodsService: AirpodsMotionService
    @Binding var blinkDetector: BlinkDetector
    let drawingMode: DrawingMode
    
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
                        guard !isPaused, areBothEyesOpen else { return }
                        
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
                    .onChange(of: areBothEyesOpen) { wasOpen, isOpen in
                        guard !isPaused else { return }

                        if wasOpen && !isOpen {
                            finishCurrentStroke()
                        } else if !wasOpen && isOpen {
                            drawingPoints = [CGPoint(
                                x: airpodsService.cursorPosition.x * proxy.size.width,
                                y: airpodsService.cursorPosition.y * proxy.size.height
                            )]
                        }
                    }
                    .onChange(of: blinkDetector.wasBothEyesClosed) { wasClosed, isClosed in
                        if !wasClosed && isClosed {
                            SketchyFeedback.lightHaptic()
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
                        .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    guard drawingMode == .free else { return }
                    completeDrawing()
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
                    finishCurrentStroke()
                    isPaused = true
                    isPauseDialogPresented = true
                } label: {
                    Image(systemName: "pause.fill")
                }
            }
        })
        .confirmationDialog(
            "Drawing paused",
            isPresented: $isPauseDialogPresented,
            titleVisibility: .visible
        ) {
            Button("Stop", role: .destructive) {
                dismiss()
            }
            Button("Resume") {
                isPaused = false
            }
        }
        .onReceive(timer) { _ in
            guard drawingMode == .game, !hasFinished, !isPaused else { return }

            if timeRemaining > 0 {
                timeRemaining -= 1
                if timeRemaining <= 3 {
                    SketchyFeedback.countdownCue()
                }
            }
            if timeRemaining <= 0 {
                completeDrawing()
            }
        }
    }
    
    private var statusInfo: some View {
        HStack {
            Label {
                Text("Blinked: \(blinkDetector.blinkCount) times")
            } icon: {
                Image(systemName: "eye")
            }
            .font(SketchyTheme.Font.body(15, weight: .semibold))
            Spacer()
            if drawingMode == .game {
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
            Text(drawingMode == .game ? "Draw dare: a cat" : "Free drawing")
                .font(SketchyTheme.Font.heading(21))
            Text(drawingMode == .game ? "Aim for cat-ish." : "Double-tap the canvas when you're finished.")
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

    private func completeDrawing() {
        guard !hasFinished else { return }
        hasFinished = true
        finishCurrentStroke()

        let data = newDrawing.dataRepresentation()
        let thumbnail = newDrawing.image(from: newDrawing.bounds, scale: 1)

        guard let thumbnailData = thumbnail.pngData() else { return }

        onDoodleCompleted(DrawingModel(
            drawingData: data,
            thumbnailData: thumbnailData,
            prompt: drawingMode == .game ? "Cat" : "",
            drawingMode: drawingMode
        ))
    }

    private var areBothEyesOpen: Bool {
        !blinkDetector.isLeftEyeClosed && !blinkDetector.isRightEyeClosed
    }

    private func finishCurrentStroke() {
        guard drawingPoints.count >= 2 else {
            drawingPoints.removeAll()
            return
        }

        let stroke = makeAirPodsStroke(from: drawingPoints)
        airPodsStrokes.append(stroke)
        drawingPoints.removeAll()
        newDrawing = PKDrawing(strokes: airPodsStrokes)
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

#Preview {
    NewDoodleView(
        airpodsService: .constant(AirpodsMotionService()),
        blinkDetector: .constant(BlinkDetector()),
        drawingMode: .game) { _ in
            //
        }
}
