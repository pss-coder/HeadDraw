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
#if os(iOS)
    
#endif
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
#if os(iOS)
            .toolbarBackground(SketchyTheme.Color.paper(for: colorScheme), for: .navigationBar)
#endif
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
        .headDrawPresentations(
            finishedDrawing: $viewModel.finishedDrawing,
            isCalibrationPresented: $viewModel.isCalibrationViewPresented,
            airpodsService: $viewModel.airpodsService,
            blinkDetector: $viewModel.blinkDetector,
            onNewDoodle: { _ in viewModel.startAnotherDoodle() },
            onDoodleSave: { viewModel.saveDrawing($0, in: modelContext) },
            onCalibrationComplete: viewModel.completeCalibration
        )
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

private extension View {
    func headDrawPresentations(
        finishedDrawing: Binding<DrawingModel?>,
        isCalibrationPresented: Binding<Bool>,
        airpodsService: Binding<AirpodsMotionService>,
        blinkDetector: Binding<BlinkDetector>,
        onNewDoodle: @escaping (DrawingModel) -> Void,
        onDoodleSave: @escaping (DrawingModel) -> Void,
        onCalibrationComplete: @escaping (DrawingMode) -> Void
    ) -> some View {
#if os(iOS)
        fullScreenCover(item: finishedDrawing) { drawing in
            RevealDoodleView(
                drawing: drawing,
                onNewDoodle: onNewDoodle,
                onDoodleSave: onDoodleSave
            )
        }
        .fullScreenCover(isPresented: isCalibrationPresented) {
            CalibrationView(
                airpodsService: airpodsService,
                blinkDetector: blinkDetector,
                onComplete: onCalibrationComplete
            )
        }
#elseif os(macOS)
        sheet(item: finishedDrawing) { drawing in
            RevealDoodleView(
                drawing: drawing,
                onNewDoodle: onNewDoodle,
                onDoodleSave: onDoodleSave
            )
        }
        .sheet(isPresented: isCalibrationPresented) {
            CalibrationView(
                airpodsService: airpodsService,
                blinkDetector: blinkDetector,
                onComplete: onCalibrationComplete
            )
        }
#endif
    }
}

#Preview {
    HomeView()
}
