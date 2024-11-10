//
//  Array.swift
//  tricorder
//
//  Created by Julian Visser on 09.11.2024.
//

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
