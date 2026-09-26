import Observation
import OSLog
import SwiftData

@MainActor
@Observable
final class HomeViewModel {
    private let logger = Logger(subsystem: "com.headdraw", category: "storage")

    var path: [AppRoute] = []
    var isCalibrationViewPresented = false

    var airpodsService = AirpodsMotionService()
    var blinkDetector = BlinkDetector()
    var selectedDrawingMode: DrawingMode = .game
    var finishedDrawing: DrawingModel?

    func startDoodle() {
        isCalibrationViewPresented = true
    }

    func completeCalibration(_ drawingMode: DrawingMode) {
        selectedDrawingMode = drawingMode
        isCalibrationViewPresented = false
        path.append(.newDoodle)
    }

    func finishDoodle(_ drawing: DrawingModel) {
        finishedDrawing = drawing

        Task { @MainActor [weak self] in
            await Task.yield()
            self?.path.removeAll()
        }
    }

    func startAnotherDoodle() {
        finishedDrawing = nil
        isCalibrationViewPresented = true
    }

    func saveDrawing(_ drawing: DrawingModel, in modelContext: ModelContext) {
        finishedDrawing = nil
        modelContext.insert(drawing)

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save drawing: \(error.localizedDescription)")
        }
    }
}
