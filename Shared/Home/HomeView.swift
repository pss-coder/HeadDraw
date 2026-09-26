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
                    NewDoodleView(onDoodleCompleted: {
                        isShowRevealDoodleViewPresented = true
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
                    Text("Doodle List")
                case .settings:
                    Text("Settings screen")
                }
            }
        }
        .fullScreenCover(isPresented: $isShowRevealDoodleViewPresented) {
            RevealDoodleView(onDoodleShare: {
                    //TODO: When user taps on share
            }, onNewDoodle: {
                    //TODO: When user wants a new doodle
                    // show alert, whether to save this one, else just new doodle
                isShowRevealDoodleViewPresented = false
                isCalibrationViewPresented = true
            }, onDoodleSave: {
                isShowRevealDoodleViewPresented = false
                //TODO: Pass data to save
            })
        }
        .fullScreenCover(isPresented: $isCalibrationViewPresented) {
            CalibrationView {
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
            
            GalleryView()
        }
        .padding()
    }
}

//TODO: to include the query, and make re-usable with a flag
struct GalleryView: View {
    let photos = (1...9).map { "photo_\($0)" }
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
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(visiblePhotos, id: \.self) { photoName in
                GeometryReader { geometry in
                    Image(systemName: "scribble.variable")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                }
                .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

#Preview {
    HomeView()
}
