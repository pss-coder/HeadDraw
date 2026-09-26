//
//  ContentView.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 19/9/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("HeadDraw")
            .font(SketchyTheme.Font.heading(38))
            .sketchyUnderline(color: SketchyTheme.Color.coral, lineWidth: 2)
            .padding()
            .sketchyPaper()
    }
}
#Preview {
    ContentView()
}
