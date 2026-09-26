//
//  GalleryListView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 26/9/26.
//

import SwiftUI

struct GalleryListView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            GalleryView()
                .padding(SketchyTheme.Spacing.medium)
        }
        .sketchyPaper()
        .navigationTitle("Gallery")
        .navigationSubtitle("Your HeadDrawings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(SketchyTheme.Color.paper(for: colorScheme), for: .navigationBar)
    }
}

#Preview {
    GalleryListView()
}
