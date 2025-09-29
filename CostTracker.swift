import Foundation
import Combine
import FirebaseFirestore

/**
 * CostTracker - API Usage Cost Tracking and Revenue Analytics
 *
 * Tracks API usage costs, calculates real-time profitability,
 * and provides insights for cost optimization.
 */
class CostTracker {
    static let shared = CostTracker()

    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let queue = DispatchQueue(label: "com.bookshelfscanner.costtracker", qos: .utility)
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Properties
    @Published var currentCosts = CostMetrics()
    @Published var revenueMetrics = RevenueMetrics()
    @Published var profitabilityAnalysis = ProfitabilityAnalysis()

    // MARK: - Cost Rates (per API call)
    private let costRates: [String: Double] = [
        "gemini": 0.0025, // $0.0025 per image (Gemini 1.5 Flash)
        "grok": 0.001,    // $0.001 per request (Grok-3-mini)
        "google_books": 0.0 // Free
    ]

    // MARK: - Revenue Rates
    private let monthlySubscriptionRate: Double = 2.99
    private let annualSubscriptionRate: Double = 29.99

    // MARK: - Initialization
    private init() {
        setupRevenueTracking()
        loadHistoricalData()
        setupPeriodicCalculations()
    }

    // MARK: - Cost Recording
    func recordCost(service: String, cost: Double? = nil, usage: Int = 1) {
        let actualCost = cost ?? (costRates[service] ?? 0.0) * Double(usage)

        queue.async {
            self.currentCosts.totalCost += actualCost
            self.currentCosts.apiUsage[service] = (self.currentCosts.apiUsage[service] ?? 0) + usage

            // Track daily costs
            let today = self.getCurrentDateString()
            if self.currentCosts.dailyCosts[today] == nil {
                self.currentCosts.dailyCosts[today] = 0.0
            }
            self.currentCosts.dailyCosts[today]! += actualCost

            // Update profitability
            self.updateProfitability()
        }

        // Track in performance monitoring
        PerformanceMonitoringService.shared.trackAPICost(service: service, cost: actualCost, usage: usage)

        // Log to analytics
        AnalyticsManager.shared.trackPerformanceMetric(
            metricName: "api_cost",
            value: actualCost,
            unit: "USD"
        )
    }

    func recordBulkCost(service: String, totalCost: Double, usageCount: Int) {
        recordCost(service: service, cost: totalCost / Double(usageCount), usage: usageCount)
    }

    // MARK: - Revenue Tracking
    private func setupRevenueTracking() {
        // Listen for subscription changes
        AuthService.shared.$currentUser
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.updateRevenueFromUser(user)
            }
            .store(in: &cancellables)

        // Listen for subscription events
        NotificationCenter.default.publisher(for: Notification.Name("SubscriptionPurchased"))
            .sink { [weak self] notification in
                if let tier = notification.userInfo?["tier"] as? UserTier,
                   let price = notification.userInfo?["price"] as? Double {
                    self?.recordRevenue(tier: tier, amount: price)
                }
            }
            .store(in: &cancellables)
    }

    func recordRevenue(tier: UserTier, amount: Double, subscriptionType: SubscriptionType = .monthly) {
        queue.async {
            self.revenueMetrics.totalRevenue += amount
            self.revenueMetrics.activeSubscriptions += 1

            // Track monthly recurring revenue
            let monthlyAmount = subscriptionType == .monthly ? amount : amount / 12.0
            self.revenueMetrics.monthlyRecurringRevenue += monthlyAmount

            // Update daily revenue
            let today = self.getCurrentDateString()
            if self.revenueMetrics.dailyRevenue[today] == nil {
                self.revenueMetrics.dailyRevenue[today] = 0.0
            }
            self.revenueMetrics.dailyRevenue[today]! += amount

            self.updateProfitability()
        }

        // Track in analytics
        AnalyticsManager.shared.trackSubscriptionCompleted(
            tier: tier,
            subscriptionId: nil,
            price: amount,
            currency: "USD"
        )
    }

    private func updateRevenueFromUser(_ user: UserProfile) {
        // This would be called when user data is loaded
        // For now, assume revenue is tracked via subscription events
    }

    // MARK: - Profitability Analysis
    private func updateProfitability() {
        profitabilityAnalysis.netProfit = revenueMetrics.totalRevenue - currentCosts.totalCost
        profitabilityAnalysis.profitMargin = revenueMetrics.totalRevenue > 0 ?
            (profitabilityAnalysis.netProfit / revenueMetrics.totalRevenue) * 100.0 : 0.0

        // Calculate cost per user
        let totalUsers = Double(revenueMetrics.activeSubscriptions)
        if totalUsers > 0 {
            profitabilityAnalysis.costPerUser = currentCosts.totalCost / totalUsers
            profitabilityAnalysis.revenuePerUser = revenueMetrics.totalRevenue / totalUsers
        }

        // Calculate break-even point
        profitabilityAnalysis.breakEvenUsers = monthlySubscriptionRate > 0 ?
            Int(ceil(currentCosts.totalCost / monthlySubscriptionRate)) : 0

        // Cost efficiency rating
        profitabilityAnalysis.costEfficiencyRating = calculateCostEfficiencyRating()
    }

    private func calculateCostEfficiencyRating() -> Double {
        // Rating from 0-100 based on various factors
        var rating = 100.0

        // Penalize high cost per user
        if profitabilityAnalysis.costPerUser > 0.5 {
            rating -= 20.0
        }

        // Penalize low profit margin
        if profitabilityAnalysis.profitMargin < 50.0 {
            rating -= 30.0
        }

        // Penalize high API costs relative to revenue
        let costToRevenueRatio = currentCosts.totalCost / max(revenueMetrics.totalRevenue, 1.0)
        if costToRevenueRatio > 0.3 {
            rating -= 25.0
        }

        return max(0.0, min(100.0, rating))
    }

    // MARK: - Cost Optimization Recommendations
    func getCostOptimizationRecommendations() -> [CostOptimizationRecommendation] {
        var recommendations = [CostOptimizationRecommendation]()

        // Check API usage efficiency
        for (service, usage) in currentCosts.apiUsage {
            let cost = Double(usage) * (costRates[service] ?? 0.0)
            if cost > revenueMetrics.totalRevenue * 0.1 { // More than 10% of revenue
                recommendations.append(CostOptimizationRecommendation(
                    type: .reduceAPIUsage,
                    service: service,
                    description: "High \(service) API costs (\(String(format: "$%.3f", cost))). Consider caching or reducing call frequency.",
                    potentialSavings: cost * 0.2, // Assume 20% reduction possible
                    priority: .high
                ))
            }
        }

        // Check for unused premium features
        if profitabilityAnalysis.profitMargin < 30.0 {
            recommendations.append(CostOptimizationRecommendation(
                type: .optimizePricing,
                service: "subscription",
                description: "Low profit margin (\(String(format: "%.1f", profitabilityAnalysis.profitMargin))%). Consider price optimization.",
                potentialSavings: revenueMetrics.monthlyRecurringRevenue * 0.1,
                priority: .medium
            ))
        }

        // Check cost per user
        if profitabilityAnalysis.costPerUser > 0.3 {
            recommendations.append(CostOptimizationRecommendation(
                type: .improveEfficiency,
                service: "overall",
                description: "High cost per user (\(String(format: "$%.2f", profitabilityAnalysis.costPerUser))). Review API usage patterns.",
                potentialSavings: profitabilityAnalysis.costPerUser * Double(revenueMetrics.activeSubscriptions) * 0.15,
                priority: .high
            ))
        }

        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    // MARK: - Historical Data
    private func loadHistoricalData() {
        // Load last 30 days of cost/revenue data
        // This would typically load from Firestore or local storage
        // For now, initialize with empty data
    }

    private func saveHistoricalData() {
        // Save current metrics to persistent storage
        // This would typically save to Firestore or local storage
    }

    // MARK: - Periodic Calculations
    private func setupPeriodicCalculations() {
        // Update calculations every hour
        Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { [weak self] _ in
            self?.queue.async {
                self?.updateProfitability()
                self?.saveHistoricalData()
            }
        }
    }

    // MARK: - Reporting
    func generateCostReport(startDate: Date, endDate: Date) async throws -> CostReport {
        // This would fetch historical data from storage
        // For now, return current data
        return CostReport(
            period: DateInterval(start: startDate, end: endDate),
            totalCosts: currentCosts.totalCost,
            totalRevenue: revenueMetrics.totalRevenue,
            netProfit: profitabilityAnalysis.netProfit,
            costBreakdown: currentCosts.apiUsage.map { service, usage in
                (service: service, cost: Double(usage) * (costRates[service] ?? 0.0), usage: usage)
            },
            recommendations: getCostOptimizationRecommendations()
        )
    }

    // MARK: - Helper Methods
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Real-time Cost Estimation
    func estimateMonthlyCost(projectionDays: Int = 30) -> Double {
        let dailyAverage = currentCosts.dailyCosts.values.reduce(0, +) / max(1, Double(currentCosts.dailyCosts.count))
        return dailyAverage * Double(projectionDays)
    }

    func estimateMonthlyRevenue(projectionDays: Int = 30) -> Double {
        let dailyAverage = revenueMetrics.dailyRevenue.values.reduce(0, +) / max(1, Double(revenueMetrics.dailyRevenue.count))
        return dailyAverage * Double(projectionDays)
    }

    // MARK: - Cost Rate Access
    func getCostRate(for service: String) -> Double {
        return costRates[service] ?? 0.0
    }
}

// MARK: - Supporting Types
struct CostMetrics {
    var totalCost: Double = 0.0
    var apiUsage: [String: Int] = [:]
    var dailyCosts: [String: Double] = [:]

    var costByService: [String: Double] {
        var result: [String: Double] = [:]
        for (service, usage) in apiUsage {
            let rate = CostTracker.shared.getCostRate(for: service)
            result[service] = Double(usage) * rate
        }
        return result
    }
}

struct RevenueMetrics {
    var totalRevenue: Double = 0.0
    var monthlyRecurringRevenue: Double = 0.0
    var activeSubscriptions: Int = 0
    var dailyRevenue: [String: Double] = [:]
}

struct ProfitabilityAnalysis {
    var netProfit: Double = 0.0
    var profitMargin: Double = 0.0
    var costPerUser: Double = 0.0
    var revenuePerUser: Double = 0.0
    var breakEvenUsers: Int = 0
    var costEfficiencyRating: Double = 0.0
}

struct CostOptimizationRecommendation {
    let type: RecommendationType
    let service: String
    let description: String
    let potentialSavings: Double
    let priority: RecommendationPriority

    enum RecommendationType {
        case reduceAPIUsage
        case optimizePricing
        case improveEfficiency
        case cacheOptimization
    }

    enum RecommendationPriority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
}

struct CostReport {
    let period: DateInterval
    let totalCosts: Double
    let totalRevenue: Double
    let netProfit: Double
    let costBreakdown: [(service: String, cost: Double, usage: Int)]
    let recommendations: [CostOptimizationRecommendation]
}

enum SubscriptionType {
    case monthly
    case annual
}