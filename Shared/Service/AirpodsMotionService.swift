//
//  AirpodsMotion.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 21/9/26.
//
//
//  AirpodsMotionService.swift
//  HeadDoodle
//
//  Owns the CMHeadphoneMotionManager stream for the whole app. One instance
//  should be created up in ContentView and injected (via .environment or a
//  binding) so CalibrationView (which locks the baseline) and
//  DrawChallengeView (which reads cursorPosition) share the same neutral
//  pitch/yaw — recreating this per-screen would lose the baseline.
//
//  Centering is button-driven rather than auto-detected: the user aligns
//  themselves against the on-screen target and taps "Calibrate" when ready,
//  and captureBaselineNow() locks the baseline from a short recent window
//  of samples (to smooth out sensor noise right at the moment of the tap).
//
import Foundation
import CoreMotion
import Observation
import AVFoundation

@Observable
final class AirpodsMotionService: NSObject {
    
        // MARK: - AirPods Motion
    
    private let headphoneMotionManager = CMHeadphoneMotionManager()
    
    private(set) var isHeadphoneConnected = false
    
    var isMotionAvailable: Bool {
        headphoneMotionManager.isDeviceMotionAvailable
    }
    
    var isDeviceMotionActive: Bool {
        headphoneMotionManager.isDeviceMotionActive
    }
    
    private var latestMotion: CMDeviceMotion?
    
        // MARK: - Calibration State
    
    private(set) var isCentered = false
    
    private(set) var centeringProgress: Double = 0
    
        /// Current live position of the user's head during calibration.
        /// 0...1 where (0.5, 0.5) is the calibrated center.
    private(set) var centeringPosition = CGPoint(
        x: 0.5,
        y: 0.5
    )
    
        // The position captured when the user presses "Calibrate"
    private var calibrationPitch: Double?
    private var calibrationYaw: Double?
    
        // When the user entered the valid calibration area
    private var calibrationStartedAt: TimeInterval?
    
        /// How long the user must remain within the calibration area.
    private let calibrationDuration: TimeInterval = 2.0
    
        /// How much the user is allowed to move while calibrating.
        ///
        /// This is in radians.
        /// 0.08 rad ≈ 4.6 degrees.
    private let calibrationTolerance: Double = 0.08
    
        // MARK: - Drawing Baseline
    
        /// Final neutral position used by the drawing cursor.
    private var neutralPitch: Double?
    private var neutralYaw: Double?
    
        // MARK: - Cursor
    
    private(set) var cursorPosition = CGPoint(
        x: 0.5,
        y: 0.5
    )
    
    private var smoothedPitch: Double = 0
    private var smoothedYaw: Double = 0
    
        /// Lower = smoother but slower.
    private let smoothingFactor: Double = 0.12
    
        /// Small movements below this are ignored.
    private let deadZone: Double = 0.03
    
        /// Drawing cursor sensitivity.
    var sensitivity: Double = 1.0
    
        // MARK: - Init
    
    override init() {
        super.init()
        headphoneMotionManager.delegate = self
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
        headphoneMotionManager.stopDeviceMotionUpdates()
    }
    
        // MARK: - AirPods Connection
    
        // MARK: - Connection
    
    @objc private func handleRouteChange(_ notification: Notification) {
        updateHeadphoneConnectionStatus()
    }
    
    private func updateHeadphoneConnectionStatus() {
        let session = AVAudioSession.sharedInstance()
        let headphoneTypes: [AVAudioSession.Port] = [.headphones, .bluetoothA2DP, .bluetoothLE, .bluetoothHFP]
        isHeadphoneConnected = session.currentRoute.outputs.contains { headphoneTypes.contains($0.portType) }
    }
    
    
        // MARK: - Motion
    
    func startDeviceMotionUpdates() {
        
        guard headphoneMotionManager.isDeviceMotionAvailable else {
            print("❌ Device motion unavailable")
            return
        }
        
        guard !headphoneMotionManager.isDeviceMotionActive else {
            return
        }
        
        print("✅ Starting AirPods device motion")
        
        headphoneMotionManager.startDeviceMotionUpdates(
            to: .main
        ) { [weak self] motion, error in
            
            guard let self,
                  let motion else {
                if let error {
                    print(
                        "❌ Motion error:",
                        error.localizedDescription
                    )
                }
                
                return
            }
            
            self.latestMotion = motion
            
            let attitude = motion.attitude
            
                // Once calibration is complete,
                // use the neutral position for drawing.
            if self.isCentered {
                
                self.updateCursor(
                    pitch: attitude.pitch,
                    yaw: attitude.yaw
                )
                
                    // If manual calibration is currently happening,
                    // track the user's head relative to the new center.
            } else if self.calibrationPitch != nil {
                
                self.processManualCalibration(
                    pitch: attitude.pitch,
                    yaw: attitude.yaw,
                    timestamp: motion.timestamp
                )
            }
        }
    }
    
    func stopDeviceMotionUpdates() {
        
        guard headphoneMotionManager.isDeviceMotionActive else {
            return
        }
        
        headphoneMotionManager.stopDeviceMotionUpdates()
        
        print("🛑 Stopped AirPods device motion")
    }
    
        // MARK: - Manual Calibration
    
        /// Call this when the user presses the "Calibrate" button.
        ///
        /// The user's CURRENT head position becomes the new center.
    func beginManualCalibration() {
        
        guard let motion = latestMotion else {
            print("⚠️ No motion data available")
            return
        }
        
        let attitude = motion.attitude
        
            // Capture the CURRENT head position.
        calibrationPitch = attitude.pitch
        calibrationYaw = attitude.yaw
        
            // Reset calibration state.
        calibrationStartedAt = nil
        centeringProgress = 0
        
        isCentered = false
        
            // The position that was just calibrated
            // is visually the center.
        centeringPosition = CGPoint(
            x: 0.5,
            y: 0.5
        )
        
        print(
            """
            🎯 NEW CALIBRATION CENTER
            
            pitch: \(attitude.pitch)
            yaw: \(attitude.yaw)
            """
        )
    }
    
        // MARK: - Calibration Processing
    
    private func processManualCalibration(
        pitch: Double,
        yaw: Double,
        timestamp: TimeInterval
    ) {
        
        guard let calibrationPitch,
              let calibrationYaw else {
            return
        }
        
            // Difference between current head position
            // and the position captured by "Calibrate".
        let deltaPitch = pitch - calibrationPitch
        
        let deltaYaw = normalizedAngleDifference(
            yaw,
            calibrationYaw
        )
        
            // Distance from the calibrated center.
        let distance = sqrt(
            deltaPitch * deltaPitch +
            deltaYaw * deltaYaw
        )
        
            // MARK: Update visual dot
        
        let movementScale = 3.0
        
        let x = 0.5 - deltaYaw * movementScale
        let y = 0.5 - deltaPitch * movementScale
        
        centeringPosition = CGPoint(
            x: clamp(x),
            y: clamp(y)
        )
        
            // MARK: Check tolerance
        
        let isInsideTolerance =
        distance <= calibrationTolerance
        
        if isInsideTolerance {
            
                // User has entered/stayed inside
                // the calibration area.
            if calibrationStartedAt == nil {
                calibrationStartedAt = timestamp
                
                print("🎯 Holding center...")
            }
            
            guard let start = calibrationStartedAt else {
                return
            }
            
            let elapsed = timestamp - start
            
            centeringProgress = min(
                elapsed / calibrationDuration,
                1.0
            )
            
                // Completed!
            if elapsed >= calibrationDuration {
                finishManualCalibration()
            }
            
        } else {
            
                // User moved outside the circle.
                // Reset the timer.
            calibrationStartedAt = nil
            centeringProgress = 0
            
            print("↩️ Moved outside calibration area")
        }
    }
    
        // MARK: - Finish Calibration
    
    private func finishManualCalibration() {
        
        guard let calibrationPitch,
              let calibrationYaw else {
            return
        }
        
            // Save the manually calibrated position
            // as the drawing baseline.
        neutralPitch = calibrationPitch
        neutralYaw = calibrationYaw
        
            // Reset smoothing.
        smoothedPitch = 0
        smoothedYaw = 0
        
            // Put cursor exactly in the center.
        cursorPosition = CGPoint(
            x: 0.5,
            y: 0.5
        )
        
        centeringPosition = CGPoint(
            x: 0.5,
            y: 0.5
        )
        
        centeringProgress = 1
        
        isCentered = true
        
        print(
            """
            ✅ CALIBRATION COMPLETE
            
            neutral pitch: \(calibrationPitch)
            neutral yaw: \(calibrationYaw)
            """
        )
    }
    
        // MARK: - Drawing Cursor
    
    private func updateCursor(
        pitch: Double,
        yaw: Double
    ) {
        
        guard let neutralPitch,
              let neutralYaw else {
            return
        }
        
            // Calculate movement relative to
            // the manually calibrated position.
        let pitchDelta = pitch - neutralPitch
        
        let yawDelta = normalizedAngleDifference(
            yaw,
            neutralYaw
        )
        
            // Apply dead zone.
        let adjustedPitch: Double
        
        if abs(pitchDelta) < deadZone {
            adjustedPitch = 0
        } else {
            adjustedPitch = pitchDelta
        }
        
        let adjustedYaw: Double
        
        if abs(yawDelta) < deadZone {
            adjustedYaw = 0
        } else {
            adjustedYaw = yawDelta
        }
        
            // Smooth movement.
        smoothedPitch +=
        (adjustedPitch - smoothedPitch)
        * smoothingFactor
        
        smoothedYaw +=
        (adjustedYaw - smoothedYaw)
        * smoothingFactor
        
            // Map head movement → screen position.
        let x =
        0.5
        - smoothedYaw * sensitivity
        
        let y =
        0.5
        - smoothedPitch * sensitivity
        
        cursorPosition = CGPoint(
            x: clamp(x),
            y: clamp(y)
        )
    }
    
        // MARK: - Helpers
    
    private func clamp(
        _ value: Double,
        min minimum: Double = 0,
        max maximum: Double = 1
    ) -> Double {
        
        Swift.min(
            Swift.max(value, minimum),
            maximum
        )
    }
    
        /// Handles yaw wrapping around -π / +π.
    private func normalizedAngleDifference(
        _ angle: Double,
        _ reference: Double
    ) -> Double {
        
        var difference = angle - reference
        
        while difference > .pi {
            difference -= 2 * .pi
        }
        
        while difference < -.pi {
            difference += 2 * .pi
        }
        
        return difference
    }
}

    // MARK: - CMHeadphoneMotionManagerDelegate

extension AirpodsMotionService: CMHeadphoneMotionManagerDelegate {
    
    func headphoneMotionManagerDidConnect(
        _ manager: CMHeadphoneMotionManager
    ) {
        
        print("🎧 CMHeadphoneMotionManager connected")
        
        isHeadphoneConnected = true
        
        startDeviceMotionUpdates()
    }
    
    func headphoneMotionManagerDidDisconnect(
        _ manager: CMHeadphoneMotionManager
    ) {
        
        print("❌ CMHeadphoneMotionManager disconnected")
        
        isHeadphoneConnected = false
        
        stopDeviceMotionUpdates()
    }
}

//
//#Preview {
//    AirpodsMotionView()
//}

