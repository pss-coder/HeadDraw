//
//  GalleryView.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 26/9/26.
//
import SwiftUI
import SwiftData

struct GalleryView: View {
    @Environment(\.colorScheme) private var colorScheme

    // Show drawings starting with most recent on top
    @Query(
        sort: \DrawingModel.createdAt,
        order: .reverse
    )
    private var drawings: [DrawingModel]
    
    let limit: Int?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]
    
    init(limit: Int? = nil) {
        self.limit = limit
    }
    
    
    
    private var displayedDrawings: [DrawingModel] {
        if let limit {
            return Array(drawings.prefix(limit))
        } else {
            return drawings
        }
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(displayedDrawings) { drawing in
                NavigationLink {
                    DoodleDetailView(drawing: drawing)
                } label: {
                    GeometryReader { geometry in
                        if let image = PlatformImage(data: drawing.thumbnailData) {
                            Image(platformImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width, height: geometry.size.width)
                        }
                    }
                    .sketchyBorder(
                        color: SketchyTheme.Color.ink(for: colorScheme).opacity(0.8),
                        fill: SketchyTheme.Color.paperShade(for: colorScheme)
                    )
                    .aspectRatio(1, contentMode: .fit)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
