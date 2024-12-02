//
//  SensorBackgroundDataHandler.swift
//
//  Created by Julian Visser on 26.11.2024.
//

import Foundation
import OSLog
import SwiftData

@ModelActor
actor SensorBackgroundDataHandler: BackgroundDataHandlerProtocol {
    func clear() throws {
        try deleteAllInstances(of: RecordingDatabaseModel.self)
    }
}

extension SensorBackgroundDataHandler {
    func add(sensor: Sensor) async throws {
        Logger.shared.debug("called on Thread \(Thread.current)")
        Logger.shared.debug("\(String.init(describing: sensor))")

        // tood make sure recording exists

        switch sensor {
        case .motion(let name, let recordingStartDate, let batch):
            let sensorDatabaseModels = batch.map {
                MotionSensorDatabaseModel(
                    sensorName: name.rawValue,
                    recordingStart: recordingStartDate,
                    data: $0
                )
            }
            try appendData(sensorDatabaseModels)

        case .statistic(let name, let recordingStartDate, let batch):
            let sensorDatabaseModels = StatisticSensorDatabaseModel(
                sensorName: name.rawValue,
                recordingStart: recordingStartDate,
                data: batch
            )
            try appendData(sensorDatabaseModels)

        case .distance(let name, let recordingStartDate, let batch):
            let sensorDatabaseModels = DistanceSensorDatabaseModel(
                sensorName: name.rawValue,
                recordingStart: recordingStartDate,
                data: batch
            )
            try appendData(sensorDatabaseModels)
        }
    }

    func getMotionSensorStructs(recordingStart: Date) throws
        -> [MergedSensorDatabaseModelStruct<MotionValue>]
    {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let descriptor = FetchDescriptor<MotionSensorDatabaseModel>(
            predicate: #Predicate<MotionSensorDatabaseModel> {
                $0.recordingStart == recordingStart
            }
        )

        let modelContext = createModelContext(
            modelContainer: modelContainer
        )

        let sensorPersistentModels = try modelContext.fetch(descriptor)

        let sensorStructs: [SensorDatabaseModelStruct<MotionValue>] = try sensorPersistentModels.map
        {
            try $0.toStruct()
        }

        let mergedSensorStructs = try getMergedSensorStructs(sensorStructs: sensorStructs)
        
        return mergedSensorStructs.sorted { $0.recordingStart < $1.recordingStart }
    }

    
    struct MergedSensorDatabaseModelStruct<T: Value> {
        let sensorName: String
        let recordingStart: Date
        let data: [T]
    }
    
    func getMergedSensorStructs<T>(sensorStructs: [SensorDatabaseModelStruct<T>]) throws -> [MergedSensorDatabaseModelStruct<T>]
    {
        
        guard let recordingStart = sensorStructs.first?.recordingStart else {
            throw SensorBackgroundDataHandlerError.empty
        }
        
        let mergedSensorBatches = sensorStructs.reduce(into: [:]) { result, sensorStruct in
            result[sensorStruct.sensorName, default: []].append(sensorStruct.data)
        }
        
        return mergedSensorBatches.map {
            MergedSensorDatabaseModelStruct(
                    sensorName: $0.key,
                    recordingStart: recordingStart,
                    data: $0.value
                )
        }
    }

    func getSensorValueBytes(recordingStart: Date) async throws -> [String: Int] {
        let sensorValues = try await getSensorData(recordingStart: recordingStart)
        return sensorValues.reduce(into: [:]) { result, sensorValue in
            let bytes = sensorValue.data.count
            result[sensorValue.sensorName, default: 0] += bytes
        }
    }
}

extension SensorBackgroundDataHandler {
}

enum SensorBackgroundDataHandlerError: Error {
    case notFound
    case empty
}
