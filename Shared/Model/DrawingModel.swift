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

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        drawingData: Data,
        thumbnailData: Data
        
    ) {
        self.id = id
        self.createdAt = createdAt
        self.drawingData = drawingData
        self.thumbnailData = thumbnailData
    }
}
