//
//  HeadDraw_MacApp.swift
//  HeadDraw-Mac
//
//  Created by Pawandeep Sekhon on 25/9/26.
//

import SwiftUI
import SwiftData

@main
struct HeadDraw_MacApp: App {
    var body: some Scene {
        WindowGroup {
            HeadDrawRootView()
        }
        .modelContainer(for: DrawingModel.self)
    }
}
