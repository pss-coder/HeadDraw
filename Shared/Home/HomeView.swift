//
//  HomeView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 25/9/26.
//

import SwiftUI

struct HomeView: View {
    @State private var path: [AppRoute] = []
    @State private var isShowRevealDoodleViewPresented : Bool = false
    
    @State private var isCalibrationViewPresented: Bool = false
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                // Play Button
                playButton
                connectionStatus
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
                    NewDoodleView(onDoodleCompleted: {
                        // how to make sure the full screen cover comes first,
                        // then behind bring back to home?
                        isShowRevealDoodleViewPresented = true
                        // we set task, so to ensure, the full screen cover comes first
                        // then behind, we handle the navigation
                        Task { @MainActor in
                            await Task.yield()
                            path.removeAll()
                        }
                    })
//                    {
//                        print("doodle finished")
//                        // when doodle finished
//                        // receive the model data, and save, and show in UI
//                        // navigate back
//                        path.removeAll() // clear teh stack
////                        if !path.isEmpty {
////                            // replace the new doodle with the view doodle with the data to add in
////                            //todo: to pass the data in to view doodle
////                            path[path.count - 1] = .view_doodle
////                            // how to have confetti, when go to this view?
////                        }
//                    }
                case .view_doodle:
                    DoodleDetailView()
                    
                case .gallery:
                    Text("Doodle List")
                case .settings:
                    Text("Settings screen")
                }
            }
        }
        .fullScreenCover(isPresented: $isShowRevealDoodleViewPresented) {
            // once doodle finishes, we show the modal, asking user to view and
            // and whether they want to save or cancel  -> brings them back to home
            RevealDoodleView(onDoodleShare: {
                    //TODO
            }, onNewDoodle: {
                    //TODO:
            }, onDoodleSave: {
                // change name to show reveal doodle sheet
                isShowRevealDoodleViewPresented = false
            })
        }
        .fullScreenCover(isPresented: $isCalibrationViewPresented) {
            CalibrationView {
                // we navigate here
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
    
    // takes up entire width
    var playButton: some View {
//        NavigationLink(value: AppRoute.new_doodle) {
//            
//            
//        }
        Button(action: {
            isCalibrationViewPresented = true
        }, label: {
            Label("Start Doodle", systemImage: "scribble.variable")
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
        })
        .padding(.horizontal) // Optional: Adds nice breathing room on the screen edges
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
            
            GalleryView()
        }
        .padding()
    }
    
    var connectionStatus: some View {
        Text("Headphone connected")
    }
}

//TODO: to include the query, and make re-usable with a flag
struct GalleryView: View {
    let photos = (1...9).map { "photo_\($0)" }
    
        // 1. Track whether the user has expanded the gallery
    @State private var isExpanded = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]
    
    var visiblePhotos: [String] {
        if isExpanded {
            return photos
        } else {
            return Array(photos.prefix(9)) // Safely takes up to the first 6 items
        }
    }
    
    var body: some View {
        //NavigationStack {
            //ScrollView {
                    // 3. Render only the currently visible photos
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(visiblePhotos, id: \.self) { photoName in
                        GeometryReader { geometry in
                            Image(systemName: "scribble.variable")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.width)
//                                .clipped()
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
    }
}

#Preview {
    HomeView()
}
