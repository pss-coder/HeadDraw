//
//  ButtonStyles.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 26/9/26.
//
import SwiftUI

struct MinimalButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    var backgroundColor: Color? = nil
    var foregroundColor: Color? = nil
    var borderColor: Color? = nil
    
    func makeBody(configuration: Configuration) -> some View {
        let background = backgroundColor ?? (
            colorScheme == .dark
            ? Color(.secondarySystemBackground)
            : .white
        )
        
        let foreground = foregroundColor ?? (
            colorScheme == .dark
            ? .white
            : .black
        )
        
        let border = borderColor ?? (
            colorScheme == .dark
            ? Color.white.opacity(0.25)
            : Color.black.opacity(0.15)
        )
        
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(border, lineWidth: 1)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(
                .easeOut(duration: 0.15),
                value: configuration.isPressed
            )
    }
}
