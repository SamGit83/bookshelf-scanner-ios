import Foundation
import UIKit

class RateLimiter {
    private let deviceId: String
    private let userDefaults = UserDefaults.standard
    private let callsKey: String
    private let hourlyLimit: Int
    private let dailyLimit: Int

    init(hourlyLimit: Int = 100, dailyLimit: Int = 1000) {
        self.hourlyLimit = hourlyLimit
        self.dailyLimit = dailyLimit
        deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        callsKey = "apiCalls_\(deviceId)"
    }

    func canMakeCall() -> Bool {
        let calls = getCalls()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)

        let hourlyCalls = calls.filter { $0 > oneHourAgo }.count
        let dailyCalls = calls.filter { $0 > oneDayAgo }.count

        return hourlyCalls < hourlyLimit && dailyCalls < dailyLimit
    }

    func recordCall() {
        var calls = getCalls()
        calls.append(Date())
        // Clean old calls older than 24 hours
        let oneDayAgo = Date().addingTimeInterval(-86400)
        calls = calls.filter { $0 > oneDayAgo }
        let timestamps = calls.map { $0.timeIntervalSince1970 }
        userDefaults.set(timestamps, forKey: callsKey)

        // Check for rate limit violations and log them
        checkAndLogRateLimitViolations(calls: calls)
    }

    private func checkAndLogRateLimitViolations(calls: [Date]) {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)

        let hourlyCalls = calls.filter { $0 > oneHourAgo }.count
        let dailyCalls = calls.filter { $0 > oneDayAgo }.count

        // Log hourly rate limit violation
        if hourlyCalls >= hourlyLimit {
            SecurityLogger.shared.logRateLimitViolation(
                service: "RateLimiter",
                endpoint: "api_calls",
                limit: hourlyLimit,
                currentCount: hourlyCalls,
                details: ["time_window": "hourly", "device_id": deviceId]
            )
        }

        // Log daily rate limit violation
        if dailyCalls >= dailyLimit {
            SecurityLogger.shared.logRateLimitViolation(
                service: "RateLimiter",
                endpoint: "api_calls",
                limit: dailyLimit,
                currentCount: dailyCalls,
                details: ["time_window": "daily", "device_id": deviceId]
            )
        }
    }

    private func getCalls() -> [Date] {
        let timestamps = userDefaults.array(forKey: callsKey) as? [TimeInterval] ?? []
        return timestamps.map { Date(timeIntervalSince1970: $0) }
    }

    func getRemainingCalls() -> (hourly: Int, daily: Int) {
        let calls = getCalls()
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)

        let hourlyCalls = calls.filter { $0 > oneHourAgo }.count
        let dailyCalls = calls.filter { $0 > oneDayAgo }.count

        return (hourly: max(0, hourlyLimit - hourlyCalls), daily: max(0, dailyLimit - dailyCalls))
    }
}