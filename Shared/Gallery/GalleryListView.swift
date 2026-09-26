//
//  GalleryListView.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 26/9/26.
//

import SwiftUI

struct GalleryListView: View {
    var body: some View {
        ScrollView {
            GalleryView()
                .padding()
        }

        .navigationTitle("Doodles")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    GalleryListView()
}
