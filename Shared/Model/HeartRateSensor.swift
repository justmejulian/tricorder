//
//  HeartRateSensor.swift
//
//  Created by Julian Visser on 23.11.2024.
//

struct HeartRateSensor: Sensor {
    let name: String = "heartRate"
    var values: [HeartRateValue]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)

        // can only be heartRate
        if self.name != name {
            throw DecodingError.dataCorruptedError(
                forKey: .name,
                in: try decoder.container(keyedBy: CodingKeys.self),
                debugDescription: "Expected name \(self.name) but found \(name)."
            )
        }

        self.values = try container.decode([HeartRateValue].self, forKey: .values)
    }
}
