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

enum CalibrationStep: Int, CaseIterable, Equatable {
    case connectAirPods
    case centerHead
    case testBlink
    //case ready
}

struct CalibrationView: View {
    
    let onComplete: () -> Void
    
    @State private var step: CalibrationStep = .connectAirPods
    
        // MARK: - Stubbed sensing state
        // Replace these with real values driven by CMHeadphoneMotionManager /
        // Vision, and the Continue buttons below will gate correctly for free.
    
        /// TODO: set from CMHeadphoneMotionManagerDelegate connect/disconnect.
    @State private var isAirPodsConnected = false
    
        /// TODO: drive from your baseline-capture routine (0...1 while sampling).
    @State private var centerHeadProgress: Double = 0
        /// TODO: flip true once a stable CMDeviceMotion.attitude has been averaged.
    @State private var isHeadCentered = false
    
        /// TODO: increment from your Vision blink-detection loop.
    @State private var detectedBlinkCount = 0
    private let requiredBlinkCount = 3
    
    @AppStorage("cursorSensitivity") private var sensitivity: Double = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            StepProgressDots(current: step)
                .padding(.top, 24)
            
            Spacer(minLength: 0)
            
            Group {
                switch step {
                case .connectAirPods:
                    ConnectAirPodsStep(isConnected: isAirPodsConnected)
                case .centerHead:
                    CenterHeadStep(isCentered: isHeadCentered, progress: centerHeadProgress)
                case .testBlink:
                    TestBlinkStep(detectedCount: detectedBlinkCount, requiredCount: requiredBlinkCount)
//                case .ready:
//                    ReadyStep(sensitivity: $sensitivity)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
            .id(step)
            
            Spacer(minLength: 0)
            
            actionButton
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .animation(.easeInOut(duration: 0.25), value: step)
            // TODO: start CMHeadphoneMotionManager updates + the Vision blink
            // session in .onAppear here, and tear them down in .onDisappear.
            // TODO: also handle mid-flow failures (AirPods disconnect, no face
            // detected) by resetting the relevant @State back to its "waiting"
            // value rather than leaving the user stuck on a stale step.
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch step {
        case .connectAirPods:
            Button("Continue") { advance() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                //TODO: TO ADD BACK, ONCE IMPLEMENTATION IS SET UP
                //.disabled(!isAirPodsConnected)
            
        case .centerHead:
            Button("Continue") { advance() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                //TODO: TO ADD BACK, ONCE IMPLEMENTATION IS SET UP
                //.disabled(!isHeadCentered)
            
        case .testBlink:
            Button("Start Doodling") { onComplete() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            //TODO: TO ADD BACK, ONCE IMPLEMENTATION IS SET UP
                //.disabled(detectedBlinkCount < requiredBlinkCount)
            
//        case .ready:
//            Button("Start drawing", action: onComplete)
//                .buttonStyle(.borderedProminent)
//                .controlSize(.large)
//                .frame(maxWidth: .infinity)
        }
    }
    
    private func advance() {
        guard let next = CalibrationStep(rawValue: step.rawValue + 1) else { return }
        step = next
    }
}

// MARK: - Step 1: Connect AirPods

private struct ConnectAirPodsStep: View {
    let isConnected: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.25), lineWidth: 2)
                    .frame(width: 112, height: 112)
                Circle()
                    .stroke(Color.accentColor.opacity(0.45), lineWidth: 2)
                    .frame(width: 84, height: 84)
                Circle()
                    .fill(isConnected ? Color.green.opacity(0.15) : Color.accentColor.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: isConnected ? "checkmark" : "headphones")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(isConnected ? .green : .accentColor)
            }
            
            VStack(spacing: 8) {
                Text(isConnected ? "AirPods connected" : "Looking for AirPods…")
                    .font(.title3.weight(.semibold))
                Text(isConnected
                     ? "You're all set to move your head as the cursor."
                     : "Put them in and make sure they're connected to this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Step 2: Center head

private struct CenterHeadStep: View {
    let isCentered: Bool
        /// 0...1, how far through the baseline-capture window we are.
    let progress: Double
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: max(progress, 0.001))
                    .stroke(isCentered ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .stroke(Color.accentColor.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [3, 4]))
                    .frame(width: 74, height: 74)
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 150, height: 150)
            
            VStack(spacing: 8) {
                Text(isCentered ? "Baseline captured" : "Hold still, looking straight ahead")
                    .font(.title3.weight(.semibold))
                Text("This is your neutral position — every tilt from here moves the cursor.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Step 3: Test blink

private struct TestBlinkStep: View {
    let detectedCount: Int
    let requiredCount: Int
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .frame(width: 140, height: 140)
                Image(systemName: "eye")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)
            }
            
            VStack(spacing: 8) {
                Text("Blink a couple times")
                    .font(.title3.weight(.semibold))
                Text("We'll use this to set your personal blink threshold.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            HStack(spacing: 10) {
                ForEach(0..<requiredCount, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(index < detectedCount ? Color.green : Color.secondary.opacity(0.15))
                        if index < detectedCount {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 36, height: 36)
                }
            }
        }
    }
}

// MARK: - Step 4: Ready

//private struct ReadyStep: View {
//    @Binding var sensitivity: Double
//    
//    var body: some View {
//        VStack(spacing: 32) {
//            VStack(alignment: .leading, spacing: 12) {
//                Label("AirPods connected", systemImage: "checkmark.circle.fill")
//                    .foregroundStyle(.green)
//                Label("Head centered", systemImage: "checkmark.circle.fill")
//                    .foregroundStyle(.green)
//                Label("Blink detection ready", systemImage: "checkmark.circle.fill")
//                    .foregroundStyle(.green)
//            }
//            .font(.subheadline.weight(.medium))
//            
//            VStack(spacing: 8) {
//                HStack {
//                    Text("Sensitivity")
//                        .font(.subheadline.weight(.medium))
//                    Spacer()
//                    Text(String(format: "%.1fx", sensitivity))
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                }
//                Slider(value: $sensitivity, in: 0.5...2.0, step: 0.1)
//            }
//            .padding(.horizontal, 32)
//        }
//    }
//}

    // MARK: - Progress dots

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
        if step.rawValue < current.rawValue { return .green }
        if step == current { return .accentColor }
        return Color.secondary.opacity(0.3)
    }
}

#Preview("Connect AirPods") {
    CalibrationView(onComplete: {})
}
