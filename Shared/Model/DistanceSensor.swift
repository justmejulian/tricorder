//
//  DistanceSensor.swift
//
//  Created by Julian Visser on 23.11.2024.
//

struct DistanceSensor: Sensor {
    let name: String = "distance"
    var values: [DistanceValue]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)

        // can only be distance
        if self.name != name {
            throw DecodingError.dataCorruptedError(
                forKey: .name,
                in: try decoder.container(keyedBy: CodingKeys.self),
                debugDescription: "Expected name \(self.name) but found \(name)."
            )
        }

        self.values = try container.decode([DistanceValue].self, forKey: .values)
    }
}
