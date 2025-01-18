//
//  FileMerger.swift
//  tricorder
//

import SwiftUI
import Foundation

class FileMerger {
    /// Combines multiple Data objects with metadata (file sizes).
    func combineFiles(_ files: [Data]) -> Data {
        var combinedData = Data()
        var fileSizes = [UInt32]()
        var header = Data()

        for file in files {
            // Append the size of each file to the header
            var fileSize = UInt32(file.count).bigEndian // Use big-endian to maintain compatibility
            header.append(Data(buffer: UnsafeBufferPointer(start: &fileSize, count: 1)))
            
            // Append the file data to the combined data
            combinedData.append(file)
        }

        // Return the header followed by the combined data
        return header + combinedData
    }

    /// Splits a combined Data object back into individual files using metadata.
    func splitFiles(from combinedData: Data) -> [Data] {
        var fileSizes = [UInt32]()
        var offset = 0

        // Extract file sizes from the header
        while offset < combinedData.count {
            let sizeRange = offset..<(offset + MemoryLayout<UInt32>.size)
            guard sizeRange.upperBound <= combinedData.count else { break }

            let sizeData = combinedData.subdata(in: sizeRange)
            fileSizes.append(UInt32(bigEndian: sizeData.withUnsafeBytes { $0.load(as: UInt32.self) }))
            offset += MemoryLayout<UInt32>.size
        }

        // Extract files based on the sizes
        var files = [Data]()
        for size in fileSizes {
            let fileRange = offset..<(offset + Int(size))
            guard fileRange.upperBound <= combinedData.count else { break }

            let fileData = combinedData.subdata(in: fileRange)
            files.append(fileData)
            offset += Int(size)
        }

        return files
    }

    /// Compresses a Data object using LZFSE.
    func compress(_ data: Data) throws -> Data {
        return try (data as NSData).compressed(using: .lzfse) as Data
    }

    /// Decompresses a Data object using LZFSE.
    func decompress(_ data: Data) throws -> Data {
        return try (data as NSData).decompressed(using: .lzfse) as Data
    }

    /// Combines, compresses, and returns the compressed Data.
    func prepareForTransfer(_ files: [Data]) throws -> Data {
        let combinedData = combineFiles(files)
        return try compress(combinedData)
    }

    /// Decompresses and splits received Data back into individual files.
    func processReceivedData(_ data: Data) throws -> [Data] {
        let decompressedData = try decompress(data)
        return splitFiles(from: decompressedData)
    }
}
