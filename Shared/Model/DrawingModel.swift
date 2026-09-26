//
//  DrawingModel.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 20/9/26.
//
import SwiftData
import Foundation
import PencilKit

@Model
final class DrawingModel{
    var id: UUID
    var createdAt: Date
    var drawingData : Data
    var thumbnailData: Data
    var prompt: String // item suggested to draw

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        drawingData: Data,
        thumbnailData: Data,
        prompt: String
        
    ) {
        self.id = id
        self.createdAt = createdAt
        self.drawingData = drawingData
        self.thumbnailData = thumbnailData
        self.prompt = prompt
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
