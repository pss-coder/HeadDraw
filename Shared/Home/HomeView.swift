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
    @Environment(HomeViewModel.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \DrawingModel.createdAt, order: .reverse)
    private var drawings: [DrawingModel]

    var body: some View {
        @Bindable var appState = appState

        NavigationStack(path: $appState.path) {
            ZStack {
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
            }
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
                case .newDoodle:
                    NewDoodleView(
                        airpodsService: $appState.airpodsService,
                        blinkDetector: $appState.blinkDetector,
                        drawingMode: appState.selectedDrawingMode,
                        onDoodleCompleted: { drawing in
                            appState.finishDoodle(drawing)
                        }
                    )
                    .navigationBarBackButtonHidden(true)
                case .gallery:
                    GalleryListView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .headDrawPresentations(
            finishedDrawing: $appState.finishedDrawing,
            isCalibrationPresented: $appState.isCalibrationViewPresented,
            airpodsService: $appState.airpodsService,
            blinkDetector: $appState.blinkDetector,
            onNewDoodle: { _ in appState.startAnotherDoodle() },
            onDoodleSave: { appState.saveDrawing($0, in: modelContext) },
            onCalibrationComplete: appState.completeCalibration
        )
    }

    private var settingsNavButton: some View {
        NavigationLink(value: AppRoute.settings) {
            Label("", systemImage: "gear")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(SketchyTheme.Color.ink(for: colorScheme))
        }
    }

    private var playButton: some View {
        Button(action: {
            appState.startDoodle()
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

            Button(action: appState.startDoodle) {
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
