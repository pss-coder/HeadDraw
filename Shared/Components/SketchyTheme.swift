import SwiftUI

enum SketchyTheme {
    enum Color {
        static func paper(for scheme: ColorScheme) -> SwiftUI.Color {
            scheme == .dark ? SwiftUI.Color(hex: 0x24221D) : SwiftUI.Color(hex: 0xF7F1DF)
        }

        static func paperShade(for scheme: ColorScheme) -> SwiftUI.Color {
            scheme == .dark ? SwiftUI.Color(hex: 0x34312A) : SwiftUI.Color(hex: 0xEAE1CA)
        }

        static func ink(for scheme: ColorScheme) -> SwiftUI.Color {
            scheme == .dark ? SwiftUI.Color(hex: 0xF4EFDF) : SwiftUI.Color(hex: 0x2D2A24)
        }

        static let coral = SwiftUI.Color(hex: 0xEA705D)
        static let teal = SwiftUI.Color(hex: 0x398F88)
        static let mustard = SwiftUI.Color(hex: 0xD6A934)
        static let canvas = SwiftUI.Color(hex: 0x202525)
    }

    enum Font {
        static func heading(_ size: CGFloat) -> SwiftUI.Font {
            .custom("ChalkboardSE-Bold", size: size, relativeTo: .title)
        }

        static func body(_ size: CGFloat = 16, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
    }

    enum Spacing {
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }

    enum Shape {
        static let lineWidth: CGFloat = 1.8
        static let cornerScale: CGFloat = 0.13
    }
}

struct SketchyBorder: SwiftUI.Shape {
    var cornerScale = SketchyTheme.Shape.cornerScale

    func path(in rect: CGRect) -> Path {
        let bounds = rect.insetBy(dx: SketchyTheme.Shape.lineWidth / 2, dy: SketchyTheme.Shape.lineWidth / 2)
        let radius = min(min(bounds.width, bounds.height) * cornerScale, 18)
        let wobble = min(max(min(bounds.width, bounds.height) * 0.012, 0.8), 2.2)
        let midX = bounds.midX
        let midY = bounds.midY
        var path = Path()

        path.move(to: CGPoint(x: bounds.minX + radius, y: bounds.minY))
        path.addQuadCurve(
            to: CGPoint(x: bounds.maxX - radius, y: bounds.minY),
            control: CGPoint(x: midX, y: bounds.minY - wobble)
        )
        path.addQuadCurve(
            to: CGPoint(x: bounds.maxX, y: bounds.minY + radius),
            control: CGPoint(x: bounds.maxX, y: bounds.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: bounds.maxX, y: bounds.maxY - radius),
            control: CGPoint(x: bounds.maxX + wobble, y: midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: bounds.maxX - radius, y: bounds.maxY),
            control: CGPoint(x: bounds.maxX, y: bounds.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: bounds.minX + radius, y: bounds.maxY),
            control: CGPoint(x: midX, y: bounds.maxY + wobble)
        )
        path.addQuadCurve(
            to: CGPoint(x: bounds.minX, y: bounds.maxY - radius),
            control: CGPoint(x: bounds.minX, y: bounds.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: bounds.minX, y: bounds.minY + radius),
            control: CGPoint(x: bounds.minX - wobble, y: midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: bounds.minX + radius, y: bounds.minY),
            control: CGPoint(x: bounds.minX, y: bounds.minY)
        )
        path.closeSubpath()
        return path
    }
}

struct SketchyUnderline: SwiftUI.Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.height * 0.55))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.height * 0.4),
            control: CGPoint(x: rect.midX, y: rect.maxY + 1)
        )
        return path
    }
}

private struct SketchyBorderModifier: ViewModifier {
    var color: SwiftUI.Color
    var lineWidth: CGFloat
    var fill: SwiftUI.Color

    func body(content: Content) -> some View {
        let shape = SketchyBorder()
        content
            .background(fill, in: shape)
            .overlay(shape.stroke(color, lineWidth: lineWidth))
    }
}

private struct SketchyPaperModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(SketchyTheme.Color.paper(for: colorScheme).ignoresSafeArea())
            .foregroundStyle(SketchyTheme.Color.ink(for: colorScheme))
            .tint(SketchyTheme.Color.teal)
    }
}

struct SketchyButtonStyle: ButtonStyle {
    enum Tone {
        case marker
        case paper
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    var tone: Tone = .marker

    func makeBody(configuration: Configuration) -> some View {
        let fill = tone == .marker
            ? SketchyTheme.Color.coral
            : SketchyTheme.Color.paperShade(for: colorScheme)
        let foreground = tone == .marker
            ? SketchyTheme.Color.ink(for: .light)
            : SketchyTheme.Color.ink(for: colorScheme)
        let outline = SketchyTheme.Color.ink(for: colorScheme).opacity(0.82)
        let shape = SketchyBorder()

        configuration.label
            .font(SketchyTheme.Font.body(16, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, SketchyTheme.Spacing.large)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(shape.fill(fill))
            .overlay(shape.stroke(outline, lineWidth: SketchyTheme.Shape.lineWidth))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .rotationEffect(.degrees(configuration.isPressed ? -0.6 : 0))
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func sketchyBorder(
        color: SwiftUI.Color,
        lineWidth: CGFloat = SketchyTheme.Shape.lineWidth,
        fill: SwiftUI.Color = .clear
    ) -> some View {
        modifier(SketchyBorderModifier(color: color, lineWidth: lineWidth, fill: fill))
    }

    func sketchyPaper() -> some View {
        modifier(SketchyPaperModifier())
    }

    func sketchyUnderline(color: SwiftUI.Color, lineWidth: CGFloat = SketchyTheme.Shape.lineWidth) -> some View {
        overlay(alignment: .bottom) {
            SketchyUnderline()
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(height: 5)
                .padding(.bottom, -2)
        }
    }
}

private extension SwiftUI.Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
