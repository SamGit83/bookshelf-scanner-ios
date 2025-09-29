import Foundation

struct Experiment: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let variants: [Variant]
    let startDate: Date
    let endDate: Date?
    let status: ExperimentStatus
    let targetAudience: TargetAudience?

    enum ExperimentStatus: String, Codable {
        case draft
        case active
        case paused
        case completed
    }

    enum TargetAudience: String, Codable {
        case all
        case freeUsers
        case premiumUsers
        case newUsers
    }

    init(id: String, name: String, description: String, variants: [Variant], startDate: Date, endDate: Date? = nil, status: ExperimentStatus = .draft, targetAudience: TargetAudience? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.variants = variants
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.targetAudience = targetAudience
    }
}