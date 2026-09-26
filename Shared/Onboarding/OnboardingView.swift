//
//  OnboardingView.swift
//  HeadDraw
//
//  A 3-step carousel introducing head-tilt movement and blink-to-draw.
//  Swipeable paging on iOS/iPadOS; Back/Next-driven on macOS, since there's
//  no swipe gesture on a windowed Mac app and TabView's .page style isn't
//  available there.
//
//  On finishing the last step, calls `onComplete` so the parent can move
//  the app phase along to calibration.
//

import SwiftUI

struct OnboardingStep: Identifiable {
    let id = UUID()
    let symbolName: String
    let title: String
    let message: String
}

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme

    let onComplete: () -> Void
    
    @State private var currentPage = 0
    
    private let steps: [OnboardingStep] = [
        OnboardingStep(
            symbolName: "airpods.gen3",
            title: "Put on your AirPods",
            message: "Their motion sensors steer your pencil. Your dignity is optional."
        ),
        OnboardingStep(
            symbolName: "headphones",
            title: "Tilt to draw",
            message: "Nudge your head to steer. Big gestures make very big regrets."
        ),
        OnboardingStep(
            symbolName: "eye",
            title: "Blink and lose ink",
            message: "Open both eyes to have pen draw. open them to lift it. Try not to nap."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
#if os(iOS)
            TabView(selection: $currentPage) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    OnboardingPage(step: step)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
#else
            OnboardingPage(step: steps[currentPage])
                .animation(.easeInOut, value: currentPage)
                .frame(maxHeight: .infinity)
#endif
            
            VStack(spacing: 20) {
                PageIndicator(pageCount: steps.count, currentPage: currentPage)
                
#if os(macOS)
                HStack(spacing: 12) {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation { currentPage -= 1 }
                        }
                        .buttonStyle(SketchyButtonStyle(tone: .paper))
                        .controlSize(.large)
                    }
                    
                    Button(action: advance) {
                        Text(isLastPage ? "Get started" : "Next")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SketchyButtonStyle())
                    .controlSize(.large)
                }
                .padding(.horizontal, 40)
#else
                Button(action: advance) {
                    Text(isLastPage ? "Get started" : "Next")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(SketchyButtonStyle())
                .padding(.horizontal, 24)
#endif
                
//                if !isLastPage {
//                    Button("Skip") {
//                        onComplete()
//                    }
//                    .font(.system(size: 14))
//                    .foregroundStyle(.secondary)
//                }
            }
            .padding(.bottom, 32)
        }
        .background(backgroundColor.ignoresSafeArea())
        .foregroundStyle(SketchyTheme.Color.ink(for: colorScheme))
        .tint(SketchyTheme.Color.teal)
#if os(macOS)
        .frame(minWidth: 480, idealWidth: 560, minHeight: 480, idealHeight: 560)
#endif
    }
    
    private var isLastPage: Bool {
        currentPage == steps.count - 1
    }
    
    private func advance() {
        if isLastPage {
            onComplete()
        } else {
            withAnimation {
                currentPage += 1
            }
        }
    }
    
    private var backgroundColor: Color {
#if os(iOS)
    SketchyTheme.Color.paper(for: colorScheme)
#else
    SketchyTheme.Color.paper(for: colorScheme)
#endif
    }
}

private struct OnboardingPage: View {
    let step: OnboardingStep
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("HeadDraw")
                .font(SketchyTheme.Font.heading(38))
                .foregroundStyle(SketchyTheme.Color.teal)
            
            ZStack {
                SketchyBorder()
                    .fill(SketchyTheme.Color.mustard.opacity(0.2))
                    .overlay {
                        SketchyBorder()
                            .stroke(SketchyTheme.Color.mustard, lineWidth: 2)
                    }
                    .frame(width: 120, height: 120)
                
                Image(systemName: step.symbolName)
                    .font(.system(size: 44, weight: .medium, design: .rounded))
                    .foregroundStyle(SketchyTheme.Color.coral)
            }
            
            VStack(spacing: 8) {
                Text(step.title)
                    .font(SketchyTheme.Font.heading(24))
                    .multilineTextAlignment(.center)
                
                Text(step.message)
                    .font(SketchyTheme.Font.body(16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}

private struct PageIndicator: View {
    let pageCount: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(
                        index == currentPage
                        ? SketchyTheme.Color.coral
                        : SketchyTheme.Color.mustard.opacity(0.35)
                    )
                    .frame(width: index == currentPage ? 18 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
