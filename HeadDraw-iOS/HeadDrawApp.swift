//
//  HeadDrawApp.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 19/9/26.
//

import SwiftUI
import SwiftData

@main
struct HeadDrawApp: App {
    var body: some Scene {
        WindowGroup {
            HeadDrawRootView()
        }
        .modelContainer(for: DrawingModel.self)
    }
}
