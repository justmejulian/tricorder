//
//  DistanceChartClassifier.swift
//  tricorder
//
//  Created by Julian Visser on 05.12.2024.
//

private func smoothValues(_ values: [MotionValue], chunkSize: Int = 50) -> [MotionValue] {
    guard !values.isEmpty else { return [] }

    let sorted = values.sorted { $0.timestamp < $1.timestamp }
    let chunked = sorted.chunked(into: chunkSize)

    // only care about the last 100 chunks
    let lastChunks = chunked.suffix(100)

    // only smoothing x
    return lastChunks.map { chunk in
        let last = chunk.last!
        let sumX = chunk.reduce(0) { $0 + $1.x }
        let avgX = sumX / Double(chunk.count)

        return MotionValue(x: avgX, y: last.y, z: last.z, timestamp: last.timestamp)
    }
}
