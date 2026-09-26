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
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $viewModel.path) {
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
                        airpodsService: $viewModel.airpodsService,
                        blinkDetector: $viewModel.blinkDetector,
                        onDoodleCompleted: { drawing in
                            viewModel.finishDoodle(drawing)
                    })
                    .navigationBarBackButtonHidden(true)
                case .gallery:
                    GalleryListView()
                case .settings:
                    Text("Settings screen")
                }
            }
        }
        .fullScreenCover(item: $viewModel.finishedDrawing) { drawing in
            RevealDoodleView(
                drawing: drawing,
                onNewDoodle: { _ in
                    viewModel.startAnotherDoodle()
                }, onDoodleSave: { drawing in
                    viewModel.saveDrawing(drawing, in: modelContext)
                })
        }
        .fullScreenCover(isPresented: $viewModel.isCalibrationViewPresented) {
            CalibrationView(
                airpodsService: $viewModel.airpodsService,
                blinkDetector: $viewModel.blinkDetector) {
                    viewModel.completeCalibration()
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
            viewModel.startDoodle()
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
    
}

#Preview {
    HomeView()
}
