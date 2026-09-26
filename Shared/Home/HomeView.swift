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
    @Environment(HomeViewModel.self) var viewModel
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \DrawingModel.createdAt, order: .reverse)
    private var drawings: [DrawingModel]
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationStack(path: $viewModel.path) {
            ZStack(content: {
                
                SketchyTheme.Color.paper(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack {
                    if drawings.isEmpty {
                        emptyState
                    } else {
                        playButton
                        gallery
                        Spacer()
                    }
                }
            })
            .navigationTitle("HeadDraw")
            .navigationSubtitle("Eyes open to Draw, blink and you miss the ink.")
            .toolbarBackground(SketchyTheme.Color.paper(for: colorScheme), for: .navigationBar)
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
                        drawingMode: viewModel.selectedDrawingMode,
                        onDoodleCompleted: { drawing in
                            viewModel.finishDoodle(drawing)
                    })
                    .navigationBarBackButtonHidden(true)
                case .gallery:
                    GalleryListView()
                case .settings:
                    SettingsView()
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
                    viewModel.completeCalibration($0)
                }
        }
    }
    
    var settingsNavButton: some View {
        NavigationLink(value: AppRoute.settings) {
            Label("", systemImage: "gear")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(SketchyTheme.Color.ink(for: colorScheme))
        }
    }
    
    var playButton: some View {
        Button(action: {
            viewModel.startDoodle()
        }, label: {
            Label("Start Doodle", systemImage: "scribble.variable")
                .font(SketchyTheme.Font.heading(23))
                .padding(.vertical, SketchyTheme.Spacing.small)
                .frame(maxWidth: .infinity)
        })
        .padding(.horizontal)
        .buttonStyle(SketchyButtonStyle())

    }
    
    var gallery: some View {
        VStack {
            HStack {
                Text("Recent HeadDrawings")
                    .font(SketchyTheme.Font.heading(22))
                Spacer()
                NavigationLink(value: AppRoute.gallery) {
                    Text("See all")
                        .font(SketchyTheme.Font.body(15, weight: .semibold))
                        .foregroundStyle(SketchyTheme.Color.teal)
                }
            }
            
            GalleryView(limit: 6)
        }
        .padding(SketchyTheme.Spacing.medium)
    }

    private var emptyState: some View {
        VStack(spacing: SketchyTheme.Spacing.medium) {
            AppIconView()

            VStack(spacing: SketchyTheme.Spacing.xSmall) {
                Text("No drawings yet")
                    .font(SketchyTheme.Font.heading(23))
                Text("Start your first HeadDrawing to fill your gallery.")
                    .font(SketchyTheme.Font.body())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SketchyTheme.Color.ink(for: colorScheme).opacity(0.75))
            }

            Button(action: viewModel.startDoodle) {
                Label("Start Drawing", systemImage: "scribble.variable")
            }
            .buttonStyle(SketchyButtonStyle())
            .frame(maxWidth: 260)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SketchyTheme.Spacing.large)
    }
    
}

#Preview {
    HomeView()
}
