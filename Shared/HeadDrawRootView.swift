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
    
    var body: some View {
        if hasCompletedOnboarding {
            HomeView()
        } else {
            // start first drawing
            OnboardingView {
                hasCompletedOnboarding = true
            }
        }
    }
}
