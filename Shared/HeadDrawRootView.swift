//
//  HeadDrawRootView.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 25/9/26.
//
import SwiftUI

struct HeadDrawRootView: View {
    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false
    @AppStorage("useDarkAppearance")
    private var useDarkAppearance = false

    @State private var appState = HomeViewModel()

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                HomeView()
                    .environment(appState)
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .preferredColorScheme(useDarkAppearance ? .dark : .light)
    }
}
