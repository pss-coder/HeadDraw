import Observation
import SwiftData

@Observable
final class HomeViewModel {
    var path: [AppRoute] = []
    var isCalibrationViewPresented = false
    
    var airpodsService:AirpodsMotionService = AirpodsMotionService()
    var blinkDetector:BlinkDetector = BlinkDetector()
    var selectedDrawingMode: DrawingMode = .game
    
    var finishedDrawing: DrawingModel?

    func startDoodle() {
        isCalibrationViewPresented = true
    }

    func completeCalibration(_ drawingMode: DrawingMode) {
        selectedDrawingMode = drawingMode
        isCalibrationViewPresented = false
        path.append(.new_doodle)
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
            debugPrint("drawing saved")
        } catch {
            print("Failed to save drawing:", error)
        }
    }
}
