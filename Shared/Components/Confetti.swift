//
//  Confetti.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 26/9/26.
//
import SwiftUI
#if os(iOS)
import SwiftUI
import SwiftUI

    // 1. Create the native UIKit Confetti Emitter
struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> ConfettiUIView {
        return ConfettiUIView()
    }
    
    func updateUIView(_ uiView: ConfettiUIView, context: Context) {}
    
    class ConfettiUIView: UIView {
            // Create two separate emitter layers
        private let leftEmitter = CAEmitterLayer()
        private let rightEmitter = CAEmitterLayer()
        private var hasBurst = false
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupEmitters()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupEmitters()
        }
        
        private func setupEmitters() {
            let emojis = ["🎉", "✨"]
            
                // --- 1. Configure Left Cannon (Shoots Up and Right) ---
            leftEmitter.emitterShape = .point
            leftEmitter.emitterCells = emojis.map { emoji in
                let cell = createBaseCell(with: emoji)
                    // -pi/3 is roughly 60 degrees up and to the right
                cell.emissionLongitude = -.pi / 3
                return cell
            }
            
                // --- 2. Configure Right Cannon (Shoots Up and Left) ---
            rightEmitter.emitterShape = .point
            rightEmitter.emitterCells = emojis.map { emoji in
                let cell = createBaseCell(with: emoji)
                    // -2*pi/3 is roughly 120 degrees up and to the left
                cell.emissionLongitude = -2 * .pi / 3
                return cell
            }
            
            layer.addSublayer(leftEmitter)
            layer.addSublayer(rightEmitter)
        }
        
            // Helper factory to keep physics identical for both sides
        private func createBaseCell(with emoji: String) -> CAEmitterCell {
            let cell = CAEmitterCell()
            cell.birthRate = 10                 // Spawns 10 items per emitter
            cell.lifetime = 4.5
            cell.velocity = 600                 // Fast velocity to cross the screen arch
            cell.velocityRange = 150
            cell.emissionRange = .pi / 8        // Tighter cone so it shoots like a stream
            cell.yAcceleration = 450            // Gravity pulling them down
            
            cell.spin = 3
            cell.spinRange = 4
            cell.scale = 0.5
            cell.scaleRange = 0.15
            cell.contents = createEmojiImage(emoji: emoji)?.cgImage
            return cell
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
                // Position the left cannon slightly inside the bottom-left boundary
            leftEmitter.emitterPosition = CGPoint(x: 30, y: bounds.height + 20)
            
                // Position the right cannon slightly inside the bottom-right boundary
            rightEmitter.emitterPosition = CGPoint(x: bounds.width - 30, y: bounds.height + 20)
            
                // Trigger a single discrete "Pop!" burst simultaneously
            if !hasBurst {
                hasBurst = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                    self?.leftEmitter.birthRate = 0
                    self?.rightEmitter.birthRate = 0
                }
            }
        }
        
        private func createEmojiImage(emoji: String) -> UIImage? {
            let font = UIFont.systemFont(ofSize: 20)
            let string = emoji as NSString
            let size = string.size(withAttributes: [.font: font])
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            string.draw(at: .zero, withAttributes: [.font: font])
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return image
        }
    }
}
#elseif os(macOS)
struct ConfettiView: View {
    var body: some View {
        EmptyView()
    }
}
#endif
//
//    // 2. Use it inside your Destination View
//struct DestinationView: View {
//    @State private var showConfetti = false
//    
//    var body: some View {
//        ZStack {
//            VStack {
//                Text("Welcome to the New Screen! 🎉")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//            }
//            
//                // Layer the confetti on top when the view appears
//            if showConfetti {
//                ConfettiView()
//                    .ignoresSafeArea()
//                    .allowsHitTesting(false) // Allows tapping buttons underneath
//            }
//        }
//        .onAppear {
//                // Trigger the animation natively on entry
//            showConfetti = true
//        }
//    }
//}


//#Preview {
//    DestinationView()
//}
