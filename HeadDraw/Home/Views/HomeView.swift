//
//  HomeView.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 19/9/26.
//

import AVFoundation
import CoreMotion
import SwiftUI
import PencilKit
import SwiftData

struct HomeView: View {
    @State private var newDrawing: PKDrawing = PKDrawing()
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var airpodsService = AirpodsMotionService()
    
    @State private var detector = BlinkDetector()
    
    @State var airpodsDrawingPoints: [CGPoint] = []
    
    @State private var cameraPosition = CGPoint.zero
    @State private var cameraDragStartPosition: CGPoint?
    let cameraWidth: CGFloat = 240
    
    let cameraHeight: CGFloat = 160
    
    let cameraPadding: CGFloat = 16
    
    // Show drawings starting with most recent on top
    @Query(
        sort: \DrawingModel.createdAt,
        order: .reverse
    )
    
    private var drawings: [DrawingModel]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Gallery")
                    .font(.title)
                    .fontWeight(.bold)
                
                headphonesCardView(isConnected: airpodsService.isHeadphoneConnected, isMotionAvailable: airpodsService.isMotionAvailable)
                
                NavigationLink {
                        GeometryReader { proxy in
                            ZStack {
                                CanvasView(
                                    drawing: $newDrawing,
                                    airpodsDrawingPoints: $airpodsDrawingPoints,
                                    cursorPosition: $airpodsService
                                        .cursorPosition, isTouching: $detector.wasBothEyesClosed) { drawing in
                                            saveDrawing(drawing)
                                        }
                                
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 12, height: 12)
                                    .position(
                                        x: airpodsService.cursorPosition.x * proxy.size.width,
                                        y: airpodsService.cursorPosition.y * proxy.size.height
                                    )
                                
                                CameraPreviewView(session: detector.session)
//                                Rectangle()
                                    .frame(
                                        width: 240,
                                        height: 160,
                                        alignment: .bottomLeading
                                    )
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 16)
                                    )
                                    .position(cameraPosition)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                if cameraDragStartPosition == nil {
                                                    cameraDragStartPosition = cameraPosition
                                                }
                                                
                                                guard let startPosition = cameraDragStartPosition else {
                                                    return
                                                }
                                                
                                                cameraPosition = CGPoint(
                                                    x: startPosition.x + value.translation.width,
                                                    y: startPosition.y + value.translation.height
                                                )
                                            }
                                            .onEnded { _ in
                                                cameraDragStartPosition = nil
                                            }
                                    )
                                    .onAppear {
                                        detector.start()
                                    }
                                    .onDisappear {
                                        detector.stop()
                                    }
                        }
                            .onChange(of: airpodsService.cursorPosition) { oldValue, newValue in
                                    // we draw points on to the canvas
                                    // we append only if eyes was closed
                                guard detector.wasBothEyesClosed else { return }
                                let position = CGPoint(x: airpodsService.cursorPosition.x * proxy.size.width,
                                                       y: airpodsService.cursorPosition.y * proxy.size.height)
                                
                                airpodsDrawingPoints
                                    .append(position)
                            }
                            .onAppear {
                                    // Bottom-left initial position
                                
                                cameraPosition = CGPoint(
                                    
                                    x: cameraWidth / 2 + cameraPadding,
                                    
                                    y: proxy.size.height - cameraHeight - (cameraHeight/2)
                                    
                                )
                            }
                    }
                        .onAppear {
                            airpodsService.startDeviceMotionUpdates()
                        }
                        .onDisappear {
                            airpodsService.stopListeningToAirPodsMotionChanges()
                        }
                        .navigationTitle(
                            "Blink Count: \(detector.blinkCount)"
                        )
                        
                } label: {
                    HStack {
                        Image(systemName: "pencil.line")
                        Text("Start Drawing")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .buttonSizing(.flexible)
                .buttonBorderShape(.roundedRectangle(radius: 8))

                List(drawings) { drawing in
                    HStack {
                        if let image = UIImage(data: drawing.thumbnailData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(
                                drawing.createdAt,
                                style: .date
                            )
                            Text(
                                drawing.createdAt,
                                style: .time
                            )
                        }
                        
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: .infinity)
            }
            .padding()
            
        }
    }
    
    private func saveDrawing(_ drawing: PKDrawing) {
        let data = drawing.dataRepresentation()
        
        let thumbnail = drawing.image(
            from: drawing.bounds,
            scale: 1
        )
        
        guard let thumbnailData = thumbnail.pngData() else {
            return
        }
        
        let drawingModel = DrawingModel(
            drawingData: data,
            thumbnailData: thumbnailData
        )
        
        modelContext.insert(drawingModel)
        
        do {
            try modelContext.save()
            debugPrint("drawing saved")
        } catch {
            print("Failed to save drawing:", error)
        }
        
        airpodsDrawingPoints.removeAll() // clean up
    }
    
}

// Components
extension HomeView {
    private func headphonesCardView(isConnected: Bool, isMotionAvailable: Bool) -> some View {
        let allGood = isConnected && isMotionAvailable
        let headphoneStatus = isConnected ? "Connected" : "Not Connected"
        let motionStatus = isMotionAvailable ? "Available" : "Unavailable"
        let bgColor: Color = allGood ? .green : (isConnected ? .yellow : .gray)
        return HStack(spacing: 16) {
            Image(systemName: "headphones.sensor.tag.radiowaves.left.and.right.fill")
                .foregroundColor(isConnected ? .green : .red)
            VStack(alignment: .leading, spacing: 4) {
                Label("Headphones: " + headphoneStatus, systemImage: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isConnected ? .green : .red)
                Label("Motion Sensor: " + motionStatus, systemImage: isMotionAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isMotionAvailable ? .green : .red)
            }
        }
        .padding()
        .background(bgColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
}
