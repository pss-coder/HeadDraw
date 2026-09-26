//
//  GalleryView.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 26/9/26.
//
import SwiftUI
import SwiftData

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    
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
                GeometryReader { geometry in
                    if let image = UIImage(data: drawing.thumbnailData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                    }
                }
                .border(.primary.opacity(0.5))
                .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}
