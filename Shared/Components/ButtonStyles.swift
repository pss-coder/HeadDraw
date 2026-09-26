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
            ? SketchyTheme.Color.paperShade(for: colorScheme)
            : SketchyTheme.Color.paper(for: colorScheme)
        )
        
        let foreground = foregroundColor ?? (
            colorScheme == .dark
            ? SketchyTheme.Color.ink(for: colorScheme)
            : SketchyTheme.Color.ink(for: colorScheme)
        )
        
        let border = borderColor ?? (
            colorScheme == .dark
            ? SketchyTheme.Color.ink(for: colorScheme).opacity(0.45)
            : SketchyTheme.Color.ink(for: colorScheme).opacity(0.65)
        )
        let shape = SketchyBorder()

        configuration.label
            .font(SketchyTheme.Font.body(16, weight: .medium))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(shape.fill(background))
            .overlay(shape.stroke(border, lineWidth: SketchyTheme.Shape.lineWidth))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .rotationEffect(.degrees(configuration.isPressed ? -0.5 : 0))
            .animation(
                .easeOut(duration: 0.15),
                value: configuration.isPressed
            )
    }
}
