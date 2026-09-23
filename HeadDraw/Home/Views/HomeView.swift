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
    
    @State var airpodsDrawingPoints: [CGPoint] = []
    
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
                                        .cursorPosition) { drawing in
                                            saveDrawing(drawing)
                                        }
                                
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 12, height: 12)
                                    .position(
                                        x: airpodsService.cursorPosition.x * proxy.size.width,
                                        y: airpodsService.cursorPosition.y * proxy.size.height
                                    )
                        }
                            .onChange(of: airpodsService.cursorPosition) { oldValue, newValue in
                                    // we draw points on to the canvas
                                    // guard oldValue != newValue else { return }
                                let position = CGPoint(x: airpodsService.cursorPosition.x * proxy.size.width,
                                                       y: airpodsService.cursorPosition.y * proxy.size.height)
                                
                                airpodsDrawingPoints
                                    .append(position)
                            }
                    }
                        .onAppear {
                            airpodsService.startDeviceMotionUpdates()
                        }
                        .onDisappear {
                            airpodsService.stopListeningToAirPodsMotionChanges()
                        }
                        
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
