import SwiftUI
#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

extension PlatformImage {
    static func named(_ name: String) -> PlatformImage? {
#if os(iOS)
        UIImage(named: name)
#elseif os(macOS)
        NSImage(named: NSImage.Name(name))
#endif
    }

    func encodedPNGData() -> Data? {
#if os(iOS)
        pngData()
#elseif os(macOS)
        guard let tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
#endif
    }
}

extension Image {
    init(platformImage: PlatformImage) {
#if os(iOS)
        self.init(uiImage: platformImage)
#elseif os(macOS)
        self.init(nsImage: platformImage)
#endif
    }
}

enum PlatformImageRenderer {
    static func pngData<Content: View>(for content: Content) -> Data? {
        let renderer = ImageRenderer(content: content)
#if os(iOS)
        return renderer.uiImage?.pngData()
#elseif os(macOS)
        return renderer.nsImage?.encodedPNGData()
#endif
    }
}