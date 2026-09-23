//
//  AirpodsMotion.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 21/9/26.
//
import CoreMotion
import SwiftUI
import AVFoundation

@Observable
class AirpodsMotionService: NSObject {
    var airpodsMotionManager: CMHeadphoneMotionManager
    = CMHeadphoneMotionManager()
    
    var isHeadphoneConnected: Bool = false
    
    override init() {
        super.init()
        airpodsMotionManager.delegate = self
        
        updateHeadphoneConnectionStatus()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        updateHeadphoneConnectionStatus()
    }
    
    private func updateHeadphoneConnectionStatus() {
        let session = AVAudioSession.sharedInstance()
        let headphonesTypes: [AVAudioSession.Port] = [.headphones, .bluetoothA2DP, .bluetoothLE, .bluetoothHFP]
        isHeadphoneConnected = session.currentRoute.outputs.contains { headphonesTypes.contains($0.portType) }
    }
    
    var isMotionAvailable: Bool {
        airpodsMotionManager.isDeviceMotionAvailable
    }
    
    var isDeviceMotionActive: Bool {
        airpodsMotionManager.isConnectionStatusActive
    }
    
    // Cursor position from 0...1
    var cursorPosition: CGPoint = CGPoint(x: 0.5, y: 0.5)

    private var neutralPitch: Double?
    private var neutralYaw: Double?
    
    private var smoothedPitch: Double = 0
    private var smoothedYaw: Double = 0
    
    private let smoothingFactor: Double = 0.12
    private let deadZone: Double = 0.03
    
    func startDeviceMotionUpdates() {
        guard airpodsMotionManager.isDeviceMotionAvailable else {
            return
        }
        
        neutralPitch = nil
        neutralYaw = nil
        
        smoothedPitch = 0
        smoothedYaw = 0
        
        airpodsMotionManager.startDeviceMotionUpdates(
            to: .main
        ) { [weak self] motion, error in
            
            guard let self, let motion else {
                return
            }
            
            let attitude = motion.attitude
            
                // Establish starting position
            if self.neutralPitch == nil {
                self.neutralPitch = attitude.pitch
                self.neutralYaw = attitude.yaw
            }
            
            self.updateCursor(
                pitch: attitude.pitch,
                yaw: attitude.yaw
            )
        }
    }
    
    private func updateCursor(
        pitch: Double,
        yaw: Double
    ) {
        guard let neutralPitch,
              let neutralYaw
        else {
            return
        }
        
        let rawPitchDelta = applyDeadZone(
            pitch - neutralPitch
        )
        
        let rawYawDelta = applyDeadZone(
            yaw - neutralYaw
        )
        
            // Exponential smoothing
        smoothedPitch +=
        (rawPitchDelta - smoothedPitch)
        * smoothingFactor
        
        smoothedYaw +=
        (rawYawDelta - smoothedYaw)
        * smoothingFactor
        
        let sensitivity = 1.5
        
        let x = min(
            max(0.5 - smoothedYaw * sensitivity, 0),
            1
        )
        
        let y = min(
            max(0.5 - smoothedPitch * sensitivity, 0),
            1
        )
        
        cursorPosition = CGPoint(
            x: x,
            y: y
        )
        
        debugPrint(cursorPosition)
    }
    
    private func applyDeadZone(_ value: Double) -> Double {
        if abs(value) < deadZone {
            return 0
        }
        
        return value
    }
    
    func stopListeningToAirPodsMotionChanges() {
        guard isDeviceMotionActive else { return }
        airpodsMotionManager.stopDeviceMotionUpdates()
        //reset 
        cursorPosition = CGPoint(x: 0.5, y: 0.5)
    }
    
    
}

extension AirpodsMotionService: CMHeadphoneMotionManagerDelegate {
   
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        debugPrint("airpods CONNECTED")
        updateHeadphoneConnectionStatus()
    }
    
    func headphoneMotionManagerDidDisconnect(
        _ manager: CMHeadphoneMotionManager
    ) {
        debugPrint("airpods DISCONNECTED")
        updateHeadphoneConnectionStatus()
    }
    
}


struct AirpodsMotionView: View {
    
    @State private var service = AirpodsMotionService()
    
    var body: some View {
        VStack {
            Text("isAvailable: \(service.isMotionAvailable)")
            Text("isActive: \(service.isDeviceMotionActive)")
            Text("isHeadphoneConnected: \(service.isHeadphoneConnected)")
            
            GeometryReader { geometry in
                
                ZStack {
                    Color(.systemBackground)
                    
                    Circle()
                        .fill(.blue)
                        .frame(width: 30, height: 30)
                        .position(
                            x: service.cursorPosition.x * geometry.size.width,
                            y: service.cursorPosition.y * geometry.size.height
                        )
                }
                .ignoresSafeArea()
            }
            .onAppear {
                service.startDeviceMotionUpdates()
            }
            .onDisappear {
                service.stopListeningToAirPodsMotionChanges()
            }
        }
    }
}

#Preview {
    AirpodsMotionView()
}

