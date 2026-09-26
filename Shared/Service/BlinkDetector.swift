//
//  BlinkDetector.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 22/9/26.
//
import SwiftUI
import AVFoundation

import Vision
import Observation

@Observable
class BlinkDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        // UI-Observable states
    var isLeftEyeClosed = false
    var isRightEyeClosed = false
    var blinkCount = 0
    var didBlink = false
    
    var errorMessage: String? = nil
    
    var isEyesOpen: Bool = true // default eye is open
    
        // Camera session properties
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.blinkdetector.sessionQueue")
    private let sequenceHandler = VNSequenceRequestHandler()
    
    // EAR Threshold parameters (tweak based on testing)
    private let blinkThreshold: CGFloat = 0.18
    var wasBothEyesClosed = false
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
            // Use front camera for face tracking
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            self.errorMessage = "Front camera unavailable."
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) { session.addInput(input) }
        
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        
            // Ensure correct camera orientation configuration
        if let connection = videoOutput.connection(with: .video) {
            // Portrait
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            connection.isVideoMirrored = true // Mirror layout to act like a natural mirror UI
        }
        
        session.commitConfiguration()
    }
    
    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            
            guard !self.session.isRunning else { return }
            
            self.session.startRunning()
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                guard self.session.isRunning else { return }
                self.session.stopRunning()
            }
        }
        // reset blink count
        isLeftEyeClosed = false
        isRightEyeClosed = false
        blinkCount = 0
        didBlink = false
        isEyesOpen = true
    }
    
        // Camera frame delegate processing loop
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceLandmarksRequest()
            // Default orientation is fine since the connection handles portrait alignment
        try? sequenceHandler.perform([request], on: imageBuffer, orientation: .up)
        
        guard let observations = request.results, let face = observations.first else {
            return
        }
        
        processFaceLandmarks(face)
    }
    
    private func processFaceLandmarks(_ face: VNFaceObservation) {
            // Extract 76-point or 2D landmark outlines
        guard let landmarks = face.landmarks,
              let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye else { return }
        
            // Compute individual Eye Aspect Ratios (EAR)
        let leftEAR = calculateEAR(for: leftEye)
        let rightEAR = calculateEAR(for: rightEye)
        
            // Evaluate states against the threshold
        let leftClosed = leftEAR < blinkThreshold
        let rightClosed = rightEAR < blinkThreshold
        
        // Safely push back updates onto the MainActor for UI reactivity
        Task { @MainActor in
            self.isLeftEyeClosed = leftClosed
            self.isRightEyeClosed = rightClosed
            
            let bothClosed = leftClosed && rightClosed
            
                // Eyes just closed
            if bothClosed && !self.wasBothEyesClosed {
                self.blinkCount += 1
            }
            
                // Eyes just opened after being closed = blink completed
            if !bothClosed && self.wasBothEyesClosed {
                self.didBlink = true
                
                // Reset on the next run-loop tick
                Task { @MainActor in
                    await Task.yield()
                    self.didBlink = false
                }
            }
            
            self.wasBothEyesClosed = bothClosed
        }
    }
    
        /// Standard EAR Calculation logic: (||p2-p6|| + ||p3-p5||) / (2 * ||p1-p4||)
    private func calculateEAR(for eyeLandmarks: VNFaceLandmarkRegion2D) -> CGFloat {
        let points = eyeLandmarks.normalizedPoints
        guard points.count >= 6 else { return 1.0 }
        
            // Map points out for geometric distance equations
        let p1 = points[0]
        let p2 = points[1]
        let p3 = points[2]
        let p4 = points[3]
        let p5 = points[4]
        let p6 = points[5]
        
        let vertical1 = distance(from: p2, to: p6)
        let vertical2 = distance(from: p3, to: p5)
        let horizontal = distance(from: p1, to: p4)
        
        guard horizontal > 0 else { return 1.0 }
        return (vertical1 + vertical2) / (2.0 * horizontal)
    }
    
    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
    }
}


struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}


struct EyeBlinkTrackerView: View {
    // Initialise using standard Swift 5.9+ @State configuration
    @State private var detector = BlinkDetector()
    
    var body: some View {
        ZStack {
                // Live background camera viewport
            CameraPreviewView(session: detector.session)
                .ignoresSafeArea()
            
                // HUD Dashboard Layout
            VStack {
                if let error = detector.errorMessage {
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                }
                
                Spacer()
                
                    // Indicators & Counter Card
                VStack(spacing: 20) {
                    Text("Total Blinks: \(detector.blinkCount)")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 40) {
                        EyeIndicatorView(label: "Left Eye", isClosed: detector.isLeftEyeClosed)
                        EyeIndicatorView(label: "Right Eye", isClosed: detector.isRightEyeClosed)
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            detector.start()
        }
        .onDisappear {
            detector.stop()
        }
    }
}

// Subview helper for indicators
struct EyeIndicatorView: View {
    let label: String
    let isClosed: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(isClosed ? Color.red : Color.green)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: isClosed ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.white)
                )
            Text(label)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}
