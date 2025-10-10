import Foundation

struct Variant: Codable, Identifiable {
    let id: String
    let name: String
    let config: [String: AnyCodable]
    let weight: Double // For weighted random assignment (0.0 to 1.0)

    enum CodingKeys: String, CodingKey {
        case id, name, config, weight
    }

    init(id: String, name: String, config: [String: AnyCodable], weight: Double = 1.0) {
        self.id = id
        self.name = name
        self.config = config
        self.weight = weight
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        config = try container.decode([String: AnyCodable].self, forKey: .config)
        weight = try container.decode(Double.self, forKey: .weight)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(config, forKey: .config)
        try container.encode(weight, forKey: .weight)
    }

    // Convenience accessors for common config keys
    var scanLimit: Int? {
        config["scanLimit"]?.value as? Int
    }

    var bookLimit: Int? {
        config["bookLimit"]?.value as? Int
    }

    var recommendationLimit: Int? {
        config["recommendationLimit"]?.value as? Int
    }

    var monthlyPrice: Double? {
        config["monthlyPrice"]?.value as? Double
    }

    var annualPrice: Double? {
        config["annualPrice"]?.value as? Double
    }
}

// Helper struct for encoding/decoding Any values
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type"))
        }
    }
}