//
//  DrawingArchiveExporter.swift
//  HeadDraw-iOS
//
//  Created by Pawandeep Sekhon on 25/9/26.
//
import Foundation

enum DrawingArchiveExporter {
    enum ExportError: LocalizedError {
        case invalidImage
        case tooManyImages

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                "A saved drawing could not be converted to an image."
            case .tooManyImages:
                "There are too many images to place in one archive."
            }
        }
    }

    private struct Entry {
        let name: Data
        let image: Data
        let checksum: UInt32
        let localHeaderOffset: UInt32
    }

    static func createArchive(images: [Data]) throws -> URL {
        guard images.count <= Int(UInt16.max) else {
            throw ExportError.tooManyImages
        }

        var archive = Data()
        var entries: [Entry] = []

        for (index, image) in images.enumerated() {
            guard let imageSize = UInt32(exactly: image.count),
                  let headerOffset = UInt32(exactly: archive.count) else {
                throw ExportError.tooManyImages
            }

            let name = Data(String(format: "HeadDrawing-%03d.png", index + 1).utf8)
            let checksum = crc32(image)
            append(UInt32(0x04034b50), to: &archive)
            append(UInt16(20), to: &archive)
            append(UInt16(0x0800), to: &archive)
            append(UInt16(0), to: &archive)
            append(UInt16(0), to: &archive)
            append(UInt16(0), to: &archive)
            append(checksum, to: &archive)
            append(imageSize, to: &archive)
            append(imageSize, to: &archive)
            append(UInt16(name.count), to: &archive)
            append(UInt16(0), to: &archive)
            archive.append(name)
            archive.append(image)

            entries.append(Entry(
                name: name,
                image: image,
                checksum: checksum,
                localHeaderOffset: headerOffset
            ))
        }

        guard let centralDirectoryOffset = UInt32(exactly: archive.count) else {
            throw ExportError.tooManyImages
        }

        for entry in entries {
            guard let imageSize = UInt32(exactly: entry.image.count) else {
                throw ExportError.tooManyImages
            }

            append(UInt32(0x02014b50), to: &archive)
            append(UInt16(20), to: &archive)
            append(UInt16(20), to: &archive)
            append(UInt16(0x0800), to: &archive)
            append(UInt16(0), to: &archive)
            append(UInt16(0), to: &archive)
            append(UInt16(0), to: &archive)
            append(entry.checksum, to: &archive)
            append(imageSize, to: &archive)
            append(imageSize, to: &archive)
            append(UInt16(entry.name.count), to: &archive)
            append(UInt16(0), to: &archive)
            append(UInt16(0), to: &archive)
            append(UInt16(0), to: &archive)
            append(UInt16(0), to: &archive)
            append(UInt32(0), to: &archive)
            append(entry.localHeaderOffset, to: &archive)
            archive.append(entry.name)
        }

        guard let centralDirectorySize = UInt32(exactly: archive.count - Int(centralDirectoryOffset)) else {
            throw ExportError.tooManyImages
        }

        append(UInt32(0x06054b50), to: &archive)
        append(UInt16(0), to: &archive)
        append(UInt16(0), to: &archive)
        append(UInt16(entries.count), to: &archive)
        append(UInt16(entries.count), to: &archive)
        append(centralDirectorySize, to: &archive)
        append(centralDirectoryOffset, to: &archive)
        append(UInt16(0), to: &archive)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("HeadDrawings-\(UUID().uuidString).zip")
        try archive.write(to: url, options: .atomic)
        return url
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var checksum = UInt32.max
        for byte in data {
            checksum ^= UInt32(byte)
            for _ in 0..<8 {
                checksum = (checksum & 1) == 1
                    ? (checksum >> 1) ^ 0xedb88320
                    : checksum >> 1
            }
        }
        return checksum ^ UInt32.max
    }

    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndianValue = value.littleEndian
        withUnsafeBytes(of: &littleEndianValue) { data.append(contentsOf: $0) }
    }
}
