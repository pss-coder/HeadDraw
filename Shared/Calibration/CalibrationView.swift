//
//  CalibrationView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 26/9/26.
//
//
//  CalibrationView.swift
//  HeadDoodle
//
//  A 4-step wizard run right before a draw (or standalone, to adjust
//  sensitivity): connect AirPods, center your head, test blink detection,
//  then a ready screen with the sensitivity slider.
//
//  All the actual sensing is stubbed out as @State + TODOs — wire these up
//  to CMHeadphoneMotionManager and your Vision blink pipeline later. The
//  screens, transitions, and gating logic are real and won't need to
//  change shape when you do.
//
import SwiftUI
import AVFoundation

enum CalibrationStep: Int, CaseIterable, Equatable {
    case connectAirPods
    case centerHead
    case testBlink
}

struct CalibrationView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Binding var airpodsService: AirpodsMotionService
    @Binding var blinkDetector: BlinkDetector

    let onComplete: () -> Void

    @State private var step: CalibrationStep = .connectAirPods

    private let requiredBlinkCount = 3

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                StepProgressDots(current: step)

                HStack {
                    Spacer()
                    Button {
                        blinkDetector.stop()
                        airpodsService.stopDeviceMotionUpdates()
                        
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(SketchyTheme.Color.paperShade(for: colorScheme), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close calibration")
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 24)

            Spacer(minLength: 0)

            Group {
                switch step {
                case .connectAirPods:
                    ConnectAirPodsStep(
                        isConnected: airpodsService.isHeadphoneConnected
                    )
                case .centerHead:
                    CenterHeadStep(
                        isCentered: airpodsService.isCentered,
                        progress: airpodsService.centeringProgress,
                        cursorPosition: airpodsService.centeringPosition,
                        onStart: {
                            SketchyFeedback.lightHaptic()
                            airpodsService.startDeviceMotionUpdates()
                            //airpodsService.beginManualCalibration()
                        },
                        onCalibrate: {
                            airpodsService.beginManualCalibration()
                        }
                        
                    )
                case .testBlink:
                    TestBlinkStep(
                        detectedCount: blinkDetector.blinkCount,
                        requiredCount: requiredBlinkCount,
                        cameraSession: blinkDetector.session,
                        onCameraStart: {
                            blinkDetector.start()
                        }
                    )
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
            .id(step)

            Spacer(minLength: 0)

            actionButton
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .background(SketchyTheme.Color.paper(for: colorScheme).ignoresSafeArea())
        .foregroundStyle(SketchyTheme.Color.ink(for: colorScheme))
        .tint(SketchyTheme.Color.teal)
        .animation(.easeInOut(duration: 0.25), value: step)
        .onChange(of: airpodsService.isCentered) { _, isCentered in
            if isCentered {
                SketchyFeedback.successHaptic()
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch step {
        case .connectAirPods:
            Button("Continue") { advance() }
                .buttonStyle(SketchyButtonStyle())
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(!airpodsService.isHeadphoneConnected)

        case .centerHead:
            Button("Continue") { advance() }
                .buttonStyle(SketchyButtonStyle())
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(!airpodsService.isCentered)
        case .testBlink:
            Button("Let's Draw") { onComplete() }
                .buttonStyle(SketchyButtonStyle())
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(blinkDetector.blinkCount < requiredBlinkCount)
        }
    }

    private func advance() {
        guard let next = CalibrationStep(rawValue: step.rawValue + 1) else { return }
        step = next
    }
}

private struct ConnectAirPodsStep: View {
    @State private var showingSupportedModels = false

    let isConnected: Bool

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(SketchyTheme.Color.teal.opacity(0.25), lineWidth: 2)
                    .frame(width: 112, height: 112)
                Circle()
                    .stroke(SketchyTheme.Color.teal.opacity(0.45), lineWidth: 2)
                    .frame(width: 84, height: 84)
                Circle()
                    .fill(isConnected ? SketchyTheme.Color.teal.opacity(0.2) : SketchyTheme.Color.mustard.opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: isConnected ? "checkmark" : "headphones")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundStyle(isConnected ? SketchyTheme.Color.teal : SketchyTheme.Color.coral)
            }

            VStack(spacing: 8) {
                Text(isConnected ? "AirPods connected" : "Looking for AirPods…")
                    .font(SketchyTheme.Font.heading(22))
                Text(isConnected
                     ? "Their motion sensors are steering your pencil."
                     : "Pop them in and connect them to this device.")
                    .font(SketchyTheme.Font.body(16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showingSupportedModels = true
            } label: {
                Label("Supported models", systemImage: "list.bullet.rectangle")
            }
            .buttonStyle(SketchyButtonStyle(tone: .paper))
            .controlSize(.small)
            .fixedSize(horizontal: true, vertical: false)
            .sheet(isPresented: $showingSupportedModels) {
                SupportedAirPodsModelsSheet()
            }
        }
    }
}

private struct CenterHeadStep: View {
    let isCentered: Bool
    let progress: Double
    let cursorPosition: CGPoint
    let onStart: () -> Void
    let onCalibrate: () -> Void

    private let targetRadius: CGFloat = 28
    @State private var cursorWasOutsideTarget = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(SketchyTheme.Color.mustard.opacity(0.28), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: max(progress, 0.001))
                    .stroke(
                        isCentered ? SketchyTheme.Color.teal : SketchyTheme.Color.coral,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.1), value: progress)
                
                // dotted circle
                Circle()
                    .stroke(
                        SketchyTheme.Color.mustard.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1.5, dash: [3, 4])
                    )
                    .frame(width: targetRadius * 2, height: targetRadius * 2)

                GeometryReader { proxy in
                    Circle()
                        .fill(isCentered ? SketchyTheme.Color.teal : SketchyTheme.Color.coral)
                        .frame(width: 10, height: 10)
                        .position(
                            x: cursorPosition.x * proxy.size.width,
                            y: cursorPosition.y * proxy.size.height
                        )
                        .animation(.easeOut(duration: 0.08), value: cursorPosition)
                        .onChange(of: cursorPosition) { oldPosition, position in
                            guard oldPosition != position else { return }
                            let deltaX = (position.x - 0.5) * proxy.size.width
                            let deltaY = (position.y - 0.5) * proxy.size.height
                            let entryRadius = targetRadius - 5
                            let isOutsideTarget = hypot(deltaX, deltaY) > entryRadius

                            if cursorWasOutsideTarget && !isOutsideTarget && !isCentered {
                                SketchyFeedback.lightHaptic()
                            }

                            cursorWasOutsideTarget = isOutsideTarget
                        }
                }
            }
            .frame(width: 150, height: 150)

            VStack(spacing: 8) {
                Text(isCentered ? "Baseline captured" : "Center your head and tap start below")
                    .font(SketchyTheme.Font.heading(22))
                    .padding()

                Text(isCentered
                     ? "You're ready to draw."
                     : "Keep the dot in the circle. Stillness: surprisingly useful.")
                    .font(SketchyTheme.Font.body(16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    onCalibrate()
                } label: {
                    Text("Start Centering")
                }
                .buttonStyle(SketchyButtonStyle(tone: .paper))
                .disabled(isCentered)
                .padding()
            }
        }
        .onAppear {
            onStart()
        }
    }
}

private struct TestBlinkStep: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var hasStarted = false
    
    let detectedCount: Int
    let requiredCount: Int
    var cameraSession: AVCaptureSession
    let onCameraStart: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                SketchyBorder()
                    .fill(SketchyTheme.Color.ink(for: colorScheme))
                    .overlay {
                        SketchyBorder()
                            .stroke(
                                SketchyTheme.Color.ink(for: colorScheme),
                                lineWidth: 2
                            )
                    }
                    .frame(width: 140, height: 140)
                if hasStarted {
                    CameraPreviewView(session: cameraSession)
                        .frame(width: 140, height: 140)
                        .clipShape(SketchyBorder())
                } else {
                    Button {
                        hasStarted = true
                        onCameraStart()
                    } label: {
                        Image(systemName: "eye")
                            .font(.system(size: 44, design: .rounded))
                            .foregroundStyle(
                                SketchyTheme.Color.mustard
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 140, height: 140)
            VStack(spacing: 8) {
                Text(hasStarted ? "Blink three times" : "Tap the eye to begin")
                    .font(SketchyTheme.Font.heading(22))
                Text(
                    hasStarted
                    ? "We're checking your blink signal. No need to make it theatrical."
                    : "Tap the eye above when you're ready. We'll use your camera to check your blink signal."
                )
                .font(SketchyTheme.Font.body(16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }
            if hasStarted {
                HStack(spacing: 10) {
                    ForEach(0..<requiredCount, id: \.self) { index in
                        ZStack {
                            Circle()
                                .fill(
                                    index < detectedCount
                                    ? SketchyTheme.Color.teal
                                    : SketchyTheme.Color.paperShade(for: colorScheme)
                                )
                            if index < detectedCount {
                                Image(systemName: "checkmark")
                                    .font(
                                        .system(
                                            size: 14,
                                            weight: .bold,
                                            design: .rounded
                                        )
                                    )
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .onChange(of: detectedCount) { oldCount, newCount in
            if newCount > oldCount {
                SketchyFeedback.lightHaptic()
            }
        }
    }
}

private struct StepProgressDots: View {
    let current: CalibrationStep

    var body: some View {
        HStack(spacing: 6) {
            ForEach(CalibrationStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(color(for: step))
                    .frame(width: step == current ? 18 : 6, height: 6)
            }
        }
    }

    private func color(for step: CalibrationStep) -> Color {
        if step.rawValue < current.rawValue { return SketchyTheme.Color.teal }
        if step == current { return SketchyTheme.Color.coral }
        return SketchyTheme.Color.mustard.opacity(0.35)
    }
}

#Preview("Connect AirPods") {
    CalibrationView(
        airpodsService: .constant(AirpodsMotionService()),
        blinkDetector: .constant(BlinkDetector()),
        onComplete: {}
    )
}
