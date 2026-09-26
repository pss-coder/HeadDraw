//
//  HomeView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 25/9/26.
//
import SwiftUI
import PencilKit
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var path: [AppRoute] = []
    
    //TODO: Pass as a View Model
    @State private var isCalibrationViewPresented: Bool = false
    
    @State private var airpodsService = AirpodsMotionService()
    @State private var blinkDetector = BlinkDetector()
    
    @State private var finishedDrawing: DrawingModel?
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                playButton
                gallery
                Spacer()
                
            }
            .navigationTitle("HeadDoodle")
            .navigationSubtitle("Doodle with your head, blink to ink")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    settingsNavButton
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .new_doodle:
                    NewDoodleView(
                        airpodsService: $airpodsService,
                        blinkDetector: $blinkDetector,
                        onDoodleCompleted: { drawing in
                        //isShowRevealDoodleViewPresented = true
                        finishedDrawing = drawing
                        // ensures full screen comes first
                        Task { @MainActor in
                            await Task.yield()
                            path.removeAll()
                        }
                    })
                    .navigationBarBackButtonHidden(true)
                case .view_doodle:
                    DoodleDetailView()
                case .gallery:
                    GalleryListView()
                case .settings:
                    Text("Settings screen")
                }
            }
        }
        .fullScreenCover(item: $finishedDrawing) { drawing in
            RevealDoodleView(
                drawing: drawing) { drawing in
                    // share drawing
                } onNewDoodle: { drawing in
                    finishedDrawing = nil
                    isCalibrationViewPresented = true
                } onDoodleSave: { drawing in
                    finishedDrawing = nil
                    saveDrawing(drawing)
                }
        }
        .fullScreenCover(isPresented: $isCalibrationViewPresented) {
            CalibrationView(
                airpodsService: $airpodsService,
                blinkDetector: $blinkDetector) {
                    isCalibrationViewPresented = false
                    path.append(AppRoute.new_doodle)
                }
        }
    }
    
    var settingsNavButton: some View {
        NavigationLink(value: AppRoute.settings) {
            Label("", systemImage: "gear")
        }
    }
    
    var playButton: some View {
        Button(action: {
            isCalibrationViewPresented = true
        }, label: {
            Label("Start Doodle", systemImage: "scribble.variable")
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
        })
        .padding(.horizontal)
        .buttonStyle(.glassProminent)

    }
    
    var gallery: some View {
        VStack {
            HStack {
                Text("Recent Doodles")
                    .font(.title3)
                    .bold()
                Spacer()
                NavigationLink(value: AppRoute.gallery) {
                    Text("View More")
                }
            }
            
            GalleryView(limit: 6)
        }
        .padding()
    }
    
    private func saveDrawing(_ drawing: DrawingModel) {
        modelContext.insert(drawing)
        
        do {
            try modelContext.save()
            debugPrint("drawing saved")
        } catch {
            print("Failed to save drawing:", error)
        }
    }
}

#Preview {
    HomeView()
}
