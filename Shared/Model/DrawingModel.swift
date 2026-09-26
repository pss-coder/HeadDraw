//
//  DrawingModel.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 20/9/26.
//
import SwiftData
import Foundation
import PencilKit

enum DrawingMode: String, CaseIterable, Codable, Identifiable {
    case free
    case game

    var id: Self { self }

    var title: String {
        switch self {
        case .free: "Free mode"
        case .game: "Game mode"
        }
    }
}

@Model
final class DrawingModel{
    var id: UUID
    var createdAt: Date
    var drawingData : Data
    var thumbnailData: Data
    var prompt: String // item suggested to draw
    var drawingModeRawValue: String = DrawingMode.game.rawValue

    var drawingMode: DrawingMode {
        DrawingMode(rawValue: drawingModeRawValue) ?? .game
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        drawingData: Data,
        thumbnailData: Data,
        prompt: String,
        drawingMode: DrawingMode = .game
        
    ) {
        self.id = id
        self.createdAt = createdAt
        self.drawingData = drawingData
        self.thumbnailData = thumbnailData
        self.prompt = prompt
        self.drawingModeRawValue = drawingMode.rawValue
    }
}

extension DrawingModel {
    var pkDrawing: PKDrawing? {
        try? PKDrawing(data: drawingData)
    }
    
    var thumbnailImage: UIImage? {
        UIImage(data: thumbnailData)
    }
}
