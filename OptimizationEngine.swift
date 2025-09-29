import Foundation
import Combine

/**
 * OptimizationEngine - AI-Powered Recommendations Engine
 *
 * Analyzes performance data, cost metrics, and user behavior to provide
 * intelligent recommendations for cost optimization and UX improvements.
 */
class OptimizationEngine {
    static let shared = OptimizationEngine()

    // MARK: - Private Properties
    private let queue = DispatchQueue(label: "com.bookshelfscanner.optimization", qos: .utility)
    private var cancellables = Set<AnyCancellable>()
    private var performanceHistory = [PerformanceSnapshot]()
    private var costHistory = [CostSnapshot]()
    private var userBehaviorPatterns = [UserBehaviorPattern]()

    // MARK: - Public Properties
    @Published var recommendations = [OptimizationRecommendation]()
    @Published var insights = [OptimizationInsight]()

    // MARK: - Initialization
    private init() {
        setupDataCollection()
        setupPeriodicAnalysis()
        loadHistoricalData()
    }

    // MARK: - Data Collection
    private func setupDataCollection() {
        // Subscribe to performance metrics
        PerformanceMonitoringService.shared.$currentMetrics
            .throttle(for: .seconds(300), scheduler: queue, latest: true) // Every 5 minutes
            .sink { [weak self] metrics in
                self?.recordPerformanceSnapshot(metrics)
            }
            .store(in: &cancellables)

        // Subscribe to cost metrics
        CostTracker.shared.$currentCosts
            .throttle(for: .seconds(600), scheduler: queue, latest: true) // Every 10 minutes
            .sink { [weak self] costs in
                self?.recordCostSnapshot(costs)
            }
            .store(in: &cancellables)

        // Subscribe to alerts
        AlertManager.shared.$recentAlerts
            .sink { [weak self] alerts in
                self?.analyzeAlertPatterns(alerts)
            }
            .store(in: &cancellables)
    }

    private func recordPerformanceSnapshot(_ metrics: PerformanceMetrics) {
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            metrics: metrics,
            activeUsers: 0, // Would be populated from analytics
            sessionDuration: 0.0
        )
        performanceHistory.append(snapshot)

        // Keep last 1000 snapshots
        if performanceHistory.count > 1000 {
            performanceHistory.removeFirst()
        }
    }

    private func recordCostSnapshot(_ costs: CostMetrics) {
        let snapshot = CostSnapshot(
            timestamp: Date(),
            costs: costs,
            revenue: CostTracker.shared.revenueMetrics.totalRevenue
        )
        costHistory.append(snapshot)

        // Keep last 500 snapshots
        if costHistory.count > 500 {
            costHistory.removeFirst()
        }
    }

    // MARK: - Analysis Engine
    private func setupPeriodicAnalysis() {
        // Run analysis every hour
        Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { [weak self] _ in
            self?.performComprehensiveAnalysis()
        }
    }

    private func performComprehensiveAnalysis() {
        queue.async {
            self.analyzeCostEfficiency()
            self.analyzePerformanceBottlenecks()
            self.analyzeUserExperience()
            self.analyzeBusinessMetrics()
            self.generateRecommendations()
            self.generateInsights()
        }
    }

    private func analyzeCostEfficiency() {
        guard costHistory.count >= 7 else { return } // Need at least a week of data

        let recentCosts = costHistory.suffix(7)
        let costTrend = calculateTrend(recentCosts.map { $0.costs.totalCost })

        // Analyze API cost efficiency
        for (service, usage) in CostTracker.shared.currentCosts.apiUsage {
            let costPerUse = CostTracker.shared.getCostRate(for: service)
            let totalCost = Double(usage) * costPerUse

            // Check if cost is increasing faster than usage
            if costTrend > 0.1 && usage > 100 { // 10% increase and significant usage
                let recommendation = OptimizationRecommendation(
                    id: UUID().uuidString,
                    type: .costOptimization,
                    title: "Optimize \(service.capitalized) API Usage",
                    description: "\(service.capitalized) costs are trending upward. Consider implementing caching or reducing call frequency.",
                    impact: .high,
                    effort: .medium,
                    potentialSavings: totalCost * 0.2,
                    data: ["service": service, "trend": costTrend, "current_cost": totalCost]
                )
                addRecommendation(recommendation)
            }
        }
    }

    private func analyzePerformanceBottlenecks() {
        guard performanceHistory.count >= 24 else { return } // Need at least 24 hours of data

        let recentMetrics = performanceHistory.suffix(24)

        // Analyze response time trends
        let responseTimes = recentMetrics.map { $0.metrics.averageResponseTime }
        let responseTimeTrend = calculateTrend(responseTimes)

        if responseTimeTrend > 0.15 { // 15% increase in response times
            let recommendation = OptimizationRecommendation(
                id: UUID().uuidString,
                type: .performance,
                title: "Optimize API Response Times",
                description: "API response times are increasing. Consider optimizing database queries or implementing response caching.",
                impact: .high,
                effort: .high,
                potentialSavings: 0.0, // Performance improvement, not direct cost savings
                data: ["trend": responseTimeTrend, "current_avg": responseTimes.last ?? 0.0]
            )
            addRecommendation(recommendation)
        }

        // Analyze memory usage patterns
        let memoryUsage = recentMetrics.map { $0.metrics.memoryUsage }
        let highMemoryCount = memoryUsage.filter { $0 > 80.0 }.count // MB

        if Double(highMemoryCount) / Double(memoryUsage.count) > 0.3 { // 30% of time
            let recommendation = OptimizationRecommendation(
                id: UUID().uuidString,
                type: .performance,
                title: "Optimize Memory Usage",
                description: "High memory usage detected frequently. Consider implementing memory pooling or reducing image cache sizes.",
                impact: .medium,
                effort: .medium,
                potentialSavings: 0.0,
                data: ["high_memory_percentage": Double(highMemoryCount) / Double(memoryUsage.count)]
            )
            addRecommendation(recommendation)
        }
    }

    private func analyzeUserExperience() {
        // Analyze crash rates and user engagement
        let crashRate = Double(PerformanceMonitoringService.shared.currentMetrics.crashCount) /
                       max(1, Double(PerformanceMonitoringService.shared.currentMetrics.apiCalls))

        if crashRate > 0.05 { // 5% crash rate
            let recommendation = OptimizationRecommendation(
                id: UUID().uuidString,
                type: .ux,
                title: "Improve App Stability",
                description: "Crash rate is above acceptable threshold. Focus on error handling and crash reporting.",
                impact: .critical,
                effort: .high,
                potentialSavings: 0.0,
                data: ["crash_rate": crashRate]
            )
            addRecommendation(recommendation)
        }

        // Analyze battery drain patterns
        let batteryMetric = PerformanceMonitoringService.shared.currentMetrics.batteryLevel
        if batteryMetric < 20.0 {
            let recommendation = OptimizationRecommendation(
                id: UUID().uuidString,
                type: .ux,
                title: "Optimize Battery Usage",
                description: "High battery drain detected. Consider reducing background processing or optimizing image processing.",
                impact: .medium,
                effort: .medium,
                potentialSavings: 0.0,
                data: ["battery_level": batteryMetric]
            )
            addRecommendation(recommendation)
        }
    }

    private func analyzeBusinessMetrics() {
        let profitability = CostTracker.shared.profitabilityAnalysis

        // Analyze conversion rate trends
        if profitability.profitMargin < 40.0 {
            let recommendation = OptimizationRecommendation(
                id: UUID().uuidString,
                type: .business,
                title: "Improve Profit Margins",
                description: "Profit margins are below target. Consider price optimization or cost reduction strategies.",
                impact: .high,
                effort: .high,
                potentialSavings: CostTracker.shared.revenueMetrics.monthlyRecurringRevenue * 0.1,
                data: ["current_margin": profitability.profitMargin, "target_margin": 40.0]
            )
            addRecommendation(recommendation)
        }

        // Analyze cost per user
        if profitability.costPerUser > 0.25 {
            let recommendation = OptimizationRecommendation(
                id: UUID().uuidString,
                type: .business,
                title: "Reduce Cost Per User",
                description: "Cost per user is high. Focus on optimizing API usage and improving user retention.",
                impact: .high,
                effort: .medium,
                potentialSavings: profitability.costPerUser * Double(CostTracker.shared.revenueMetrics.activeSubscriptions) * 0.15,
                data: ["cost_per_user": profitability.costPerUser]
            )
            addRecommendation(recommendation)
        }
    }

    private func analyzeAlertPatterns(_ alerts: [PerformanceAlert]) {
        let recentAlerts = alerts.filter { $0.timestamp > Date().addingTimeInterval(-3600) } // Last hour

        // Group alerts by type
        let alertGroups = Dictionary(grouping: recentAlerts) { $0.type }

        for (type, typeAlerts) in alertGroups {
            if typeAlerts.count >= 3 { // Multiple alerts of same type
                let recommendation = OptimizationRecommendation(
                    id: UUID().uuidString,
                    type: .monitoring,
                    title: "Address Frequent \(type.displayName) Alerts",
                    description: "Multiple \(type.displayName.lowercased()) alerts detected. Investigate root cause and implement fixes.",
                    impact: .high,
                    effort: .high,
                    potentialSavings: 0.0,
                    data: ["alert_type": type.rawValue, "count": typeAlerts.count]
                )
                addRecommendation(recommendation)
            }
        }
    }

    // MARK: - Recommendation Generation
    private func generateRecommendations() {
        // Prioritize recommendations by impact and effort
        recommendations.sort { (r1, r2) -> Bool in
            let impactScore1 = r1.impact.rawValue * 3 - r1.effort.rawValue
            let impactScore2 = r2.impact.rawValue * 3 - r2.effort.rawValue
            return impactScore1 > impactScore2
        }

        // Keep top 10 recommendations
        if recommendations.count > 10 {
            recommendations = Array(recommendations.prefix(10))
        }
    }

    private func addRecommendation(_ recommendation: OptimizationRecommendation) {
        // Check if similar recommendation already exists
        if !recommendations.contains(where: { $0.type == recommendation.type && $0.title == recommendation.title }) {
            recommendations.append(recommendation)
        }
    }

    // MARK: - Insight Generation
    private func generateInsights() {
        insights.removeAll()

        // Generate cost insights
        let costEfficiency = CostTracker.shared.profitabilityAnalysis.costEfficiencyRating
        if costEfficiency < 70.0 {
            insights.append(OptimizationInsight(
                id: UUID().uuidString,
                category: .cost,
                title: "Cost Efficiency Needs Improvement",
                description: "Your cost efficiency rating is \(String(format: "%.1f", costEfficiency))/100. Focus on optimizing API usage and reducing unnecessary costs.",
                confidence: 0.85,
                data: ["efficiency_rating": costEfficiency]
            ))
        }

        // Generate performance insights
        let avgResponseTime = PerformanceMonitoringService.shared.currentMetrics.averageResponseTime
        if avgResponseTime > 3.0 {
            insights.append(OptimizationInsight(
                id: UUID().uuidString,
                category: .performance,
                title: "Slow API Response Times",
                description: "Average API response time is \(String(format: "%.2f", avgResponseTime))s. Users may experience delays.",
                confidence: 0.9,
                data: ["avg_response_time": avgResponseTime]
            ))
        }

        // Generate UX insights
        let crashRate = Double(PerformanceMonitoringService.shared.currentMetrics.crashCount) /
                       max(1, Double(PerformanceMonitoringService.shared.currentMetrics.apiCalls))
        if crashRate > 0.02 {
            insights.append(OptimizationInsight(
                id: UUID().uuidString,
                category: .ux,
                title: "App Stability Issues",
                description: "Crash rate of \(String(format: "%.2f", crashRate * 100))% detected. This may impact user experience.",
                confidence: 0.95,
                data: ["crash_rate": crashRate]
            ))
        }

        // Keep top 5 insights
        insights = Array(insights.prefix(5))
    }

    // MARK: - AI-Powered Analysis
    func generateAIOptimizationPlan() async -> AIOptimizationPlan {
        // This would integrate with an AI service to generate comprehensive optimization plans
        // For now, return a basic plan based on current data

        let costRecommendations = recommendations.filter { $0.type == .costOptimization }
        let performanceRecommendations = recommendations.filter { $0.type == .performance }
        let uxRecommendations = recommendations.filter { $0.type == .ux }

        return AIOptimizationPlan(
            id: UUID().uuidString,
            generatedAt: Date(),
            costOptimizations: costRecommendations,
            performanceOptimizations: performanceRecommendations,
            uxImprovements: uxRecommendations,
            businessRecommendations: recommendations.filter { $0.type == .business },
            estimatedImpact: calculateEstimatedImpact(),
            implementationPriority: .high,
            timeHorizon: .medium
        )
    }

    private func calculateEstimatedImpact() -> OptimizationImpact {
        let totalSavings = recommendations.reduce(0) { $0 + $1.potentialSavings }
        let highImpactCount = recommendations.filter { $0.impact == .high || $0.impact == .critical }.count

        return OptimizationImpact(
            costSavings: totalSavings,
            performanceImprovement: Double(highImpactCount) * 15.0, // Estimated 15% improvement per high-impact fix
            userExperienceScore: Double(recommendations.filter { $0.type == .ux }.count) * 10.0,
            businessImpact: highImpactCount >= 3 ? .high : .medium
        )
    }

    // MARK: - Utility Methods
    private func calculateTrend(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }

        let firstHalf = values.prefix(values.count / 2)
        let secondHalf = values.suffix(values.count / 2)

        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)

        guard firstAvg > 0 else { return 0.0 }
        return (secondAvg - firstAvg) / firstAvg
    }

    private func loadHistoricalData() {
        // Load historical data from storage
        // Implementation would depend on persistence strategy
    }

    // MARK: - Public API
    func getRecommendations(for type: OptimizationType? = nil, limit: Int = 10) -> [OptimizationRecommendation] {
        let filtered = type != nil ? recommendations.filter { $0.type == type } : recommendations
        return Array(filtered.prefix(limit))
    }

    func getInsights(for category: InsightCategory? = nil, limit: Int = 5) -> [OptimizationInsight] {
        let filtered = category != nil ? insights.filter { $0.category == category } : insights
        return Array(filtered.prefix(limit))
    }

    func markRecommendationImplemented(_ recommendationId: String) {
        if let index = recommendations.firstIndex(where: { $0.id == recommendationId }) {
            recommendations.remove(at: index)
        }
    }
}

// MARK: - Supporting Types
struct PerformanceSnapshot {
    let timestamp: Date
    let metrics: PerformanceMetrics
    let activeUsers: Int
    let sessionDuration: Double
}

struct CostSnapshot {
    let timestamp: Date
    let costs: CostMetrics
    let revenue: Double
}

struct UserBehaviorPattern {
    let pattern: String
    let frequency: Double
    let impact: Double
}

struct OptimizationRecommendation {
    let id: String
    let type: OptimizationType
    let title: String
    let description: String
    let impact: OptimizationImpactLevel
    let effort: OptimizationEffort
    let potentialSavings: Double
    let data: [String: Any]
    let createdAt: Date = Date()
}

struct OptimizationInsight {
    let id: String
    let category: InsightCategory
    let title: String
    let description: String
    let confidence: Double
    let data: [String: Any]
    let generatedAt: Date = Date()
}

struct AIOptimizationPlan {
    let id: String
    let generatedAt: Date
    let costOptimizations: [OptimizationRecommendation]
    let performanceOptimizations: [OptimizationRecommendation]
    let uxImprovements: [OptimizationRecommendation]
    let businessRecommendations: [OptimizationRecommendation]
    let estimatedImpact: OptimizationImpact
    let implementationPriority: OptimizationPriority
    let timeHorizon: OptimizationTimeHorizon
}

struct OptimizationImpact {
    let costSavings: Double
    let performanceImprovement: Double // Percentage
    let userExperienceScore: Double // Points
    let businessImpact: OptimizationImpactLevel
}

enum OptimizationType {
    case costOptimization
    case performance
    case ux
    case business
    case monitoring
}

enum OptimizationImpactLevel: Int {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

enum OptimizationEffort: Int {
    case low = 1
    case medium = 2
    case high = 3
}

enum InsightCategory {
    case cost
    case performance
    case ux
    case business
}

enum OptimizationPriority {
    case low
    case medium
    case high
}

enum OptimizationTimeHorizon {
    case short // 1-2 weeks
    case medium // 1-3 months
    case long // 3-6 months
}