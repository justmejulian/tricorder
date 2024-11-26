//
//  Sensor.swift
//
//  Created by Julian Visser on 05.11.2024.
//

import Foundation

protocol Sensor: Codable {
    associatedtype T: Value

    var recordingStart: Date { get }
    var values: [T] { get set }
}

enum SensorType: String, Codable {
    case motion
    case heartRate
    case distance
}

enum SensorData: Codable {
    case motion(MotionValue)
    case heartRate(HeartRateValue)
    case distance(DistanceValue)
    
    var type: SensorType {
        switch self {
        case .motion: return .motion
        case .heartRate: return .heartRate
        case .distance: return .distance
        }
    }
    
    var timestamp: Date {
        switch self {
        case .motion(let motionValue): return motionValue.timestamp
        case .heartRate(let heartRateValue): return heartRateValue.timestamp
        case .distance(let distanceValue): return distanceValue.timestamp
        }
    }
}
