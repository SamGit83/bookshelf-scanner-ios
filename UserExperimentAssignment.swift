import Foundation

struct UserExperimentAssignment: Codable, Identifiable {
    let id: String // Could be "\(userId)_\(experimentId)"
    let userId: String
    let experimentId: String
    let variantId: String
    let assignedAt: Date

    init(userId: String, experimentId: String, variantId: String, assignedAt: Date = Date()) {
        self.id = "\(userId)_\(experimentId)"
        self.userId = userId
        self.experimentId = experimentId
        self.variantId = variantId
        self.assignedAt = assignedAt
    }
}