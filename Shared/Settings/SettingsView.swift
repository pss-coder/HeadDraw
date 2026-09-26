//
//  Settings.swift
//  HeadDraw
//
//  Created by Pawandeep Sekhon on 25/9/26.
//
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("useDarkAppearance") private var useDarkAppearance = false
    @Query(sort: \DrawingModel.createdAt, order: .reverse)
    private var drawings: [DrawingModel]

    @State private var isDeleteConfirmationPresented = false
    @State private var isAboutPresented = false
    @State private var archiveURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Appearance") {
                Toggle(isOn: $useDarkAppearance) {
                    Label("Dark mode", systemImage: useDarkAppearance ? "moon.fill" : "sun.max.fill")
                }
            }

            Section("Your drawings") {
                if !drawings.isEmpty, let archiveURL {
                    ShareLink(
                        item: archiveURL,
                        preview: SharePreview("HeadDrawings.zip")
                    ) {
                        Label("Export all images", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Label("Preparing image export…", systemImage: "archivebox")
                        .foregroundStyle(.secondary)
                        .disabled(true)
                }

                Button(role: .destructive) {
                    isDeleteConfirmationPresented = true
                } label: {
                    Label("Delete all drawings", systemImage: "trash")
                }
                .disabled(drawings.isEmpty)
            }

            Section("About") {
                Button {
                    isAboutPresented = true
                } label: {
                    Label("About me", systemImage: "person.crop.circle")
                }
            }
        }
        .navigationTitle("Settings")
        .task(id: drawings.map(\.id)) {
            prepareArchive()
        }
        .confirmationDialog(
            "Delete all drawings?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete All Drawings", role: .destructive, action: deleteAllDrawings)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes all saved drawings and cannot be undone.")
        }
        .sheet(isPresented: $isAboutPresented) {
            AboutMeSheet()
                .presentationDetents([.medium])
        }
        .alert("Unable to complete action", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func deleteAllDrawings() {
        for drawing in drawings {
            modelContext.delete(drawing)
        }

        do {
            try modelContext.save()
            archiveURL = nil
        } catch {
            errorMessage = "Your drawings could not be deleted. \(error.localizedDescription)"
        }
    }

    private func prepareArchive() {
        guard !drawings.isEmpty else {
            archiveURL = nil
            return
        }

        do {
            let images = try drawings.map { drawing -> Data in
                guard let image = drawing.thumbnailImage, let data = image.pngData() else {
                    throw DrawingArchiveExporter.ExportError.invalidImage
                }
                return data
            }
            archiveURL = try DrawingArchiveExporter.createArchive(images: images)
        } catch {
            archiveURL = nil
            errorMessage = "The image archive could not be prepared. \(error.localizedDescription)"
        }
    }
}

private struct AboutMeSheet: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "scribble.variable")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(SketchyTheme.Color.coral)
            Text("About HeadDraw")
                .font(SketchyTheme.Font.heading(25))
            Text("I'm Pawandeep, the maker of HeadDraw. I built this little app to make drawing feel playful, hands-free, and a bit unexpected.")
                .font(SketchyTheme.Font.body())
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SketchyTheme.Color.paper(for: .light))
    }
}
