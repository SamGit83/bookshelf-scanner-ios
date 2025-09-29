import Foundation
import FirebaseFirestore
import Combine

/**
 * IterationTracker - Workflow management from feedback to implementation
 *
 * Manages the lifecycle of user feedback implementation tasks, from initial
 * feedback processing through prioritization, assignment, and completion tracking.
 */
class IterationTracker {
    static let shared = IterationTracker()

    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    // Published properties for SwiftUI integration
    @Published var tasks: [IterationTask] = []
    @Published var activeTasks: [IterationTask] = []
    @Published var completedTasks: [IterationTask] = []

    private init() {
        loadTasks()
        setupRealTimeUpdates()
    }

    // MARK: - Task Management

    func addTask(_ task: IterationTask) async {
        do {
            try await saveTask(task)
            await MainActor.run {
                self.tasks.append(task)
                self.updateFilteredTasks()
            }

            // Track task creation
            AnalyticsManager.shared.trackFeatureUsage(feature: "iteration_task_created", context: task.type.rawValue)

        } catch {
            print("Failed to add task: \(error)")
        }
    }

    func updateTask(_ task: IterationTask) async {
        do {
            try await saveTask(task)

            await MainActor.run {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks[index] = task
                    self.updateFilteredTasks()
                }
            }

            // Track status changes
            AnalyticsManager.shared.trackFeatureUsage(feature: "iteration_task_updated", context: task.status.rawValue)

        } catch {
            print("Failed to update task: \(error)")
        }
    }

    func deleteTask(_ taskId: String) async {
        do {
            try await db.collection("iterationTasks").document(taskId).delete()

            await MainActor.run {
                self.tasks.removeAll { $0.id == taskId }
                self.updateFilteredTasks()
            }

        } catch {
            print("Failed to delete task: \(error)")
        }
    }

    // MARK: - Task Queries

    func getTasks(for type: IterationTaskType? = nil, status: IterationStatus? = nil, priority: IterationPriority? = nil) -> [IterationTask] {
        var filtered = tasks

        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }

        if let status = status {
            filtered = filtered.filter { $0.status == status }
        }

        if let priority = priority {
            filtered = filtered.filter { $0.priority == priority }
        }

        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    func getTasksByPriority() -> [IterationPriority: [IterationTask]] {
        var grouped: [IterationPriority: [IterationTask]] = [:]

        for priority in IterationPriority.allCases {
            grouped[priority] = getTasks(priority: priority, status: .pending)
        }

        return grouped
    }

    func getOverdueTasks() -> [IterationTask] {
        let now = Date()
        return tasks.filter { task in
            task.status != .completed && task.status != .cancelled &&
            task.dueDate != nil && task.dueDate! < now
        }
    }

    // MARK: - Bulk Operations

    func bulkUpdateStatus(for taskIds: [String], to status: IterationStatus) async {
        for taskId in taskIds {
            if var task = tasks.first(where: { $0.id == taskId }) {
                task.status = status
                task.updatedAt = Date()
                await updateTask(task)
            }
        }
    }

    func bulkUpdatePriority(for taskIds: [String], to priority: IterationPriority) async {
        for taskId in taskIds {
            if var task = tasks.first(where: { $0.id == taskId }) {
                task.priority = priority
                task.updatedAt = Date()
                await updateTask(task)
            }
        }
    }

    // MARK: - Analytics and Reporting

    func getTaskMetrics() -> TaskMetrics {
        let total = tasks.count
        let completed = tasks.filter { $0.status == .completed }.count
        let pending = tasks.filter { $0.status == .pending }.count
        let inProgress = tasks.filter { $0.status == .inProgress }.count

        let avgCompletionTime = calculateAverageCompletionTime()
        let overdueCount = getOverdueTasks().count

        return TaskMetrics(
            totalTasks: total,
            completedTasks: completed,
            pendingTasks: pending,
            inProgressTasks: inProgress,
            averageCompletionTime: avgCompletionTime,
            overdueTasks: overdueCount
        )
    }

    private func calculateAverageCompletionTime() -> TimeInterval? {
        let completedTasks = tasks.filter { $0.status == .completed && $0.completedAt != nil }
        guard !completedTasks.isEmpty else { return nil }

        let totalTime = completedTasks.reduce(0) { sum, task in
            sum + (task.completedAt!.timeIntervalSince(task.createdAt))
        }

        return totalTime / Double(completedTasks.count)
    }

    func getTasksByType() -> [IterationTaskType: Int] {
        var counts: [IterationTaskType: Int] = [:]

        for task in tasks {
            counts[task.type, default: 0] += 1
        }

        return counts
    }

    func getFeedbackToImplementationCycleTime() -> TimeInterval? {
        let completedTasks = tasks.filter { $0.status == .completed && $0.createdFrom != nil }
        guard !completedTasks.isEmpty else { return nil }

        let totalTime = completedTasks.reduce(0) { sum, task in
            sum + (task.completedAt!.timeIntervalSince(task.createdAt))
        }

        return totalTime / Double(completedTasks.count)
    }

    // MARK: - Task Creation from Feedback

    func createTaskFromFeedback(
        title: String,
        description: String,
        type: IterationTaskType,
        priority: IterationPriority,
        userId: String,
        surveyType: String,
        actionableItems: [String]
    ) async {
        let task = IterationTask(
            id: UUID().uuidString,
            title: title,
            description: description,
            type: type,
            priority: priority,
            status: .pending,
            createdFrom: nil, // Will be set when linked to specific feedback
            userId: userId,
            surveyType: surveyType,
            actionableItems: actionableItems,
            createdAt: Date()
        )

        await addTask(task)
    }

    // MARK: - Real-time Updates

    private func setupRealTimeUpdates() {
        db.collection("iterationTasks")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    print("Error fetching tasks: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                Task {
                    let tasks = documents.compactMap { try? $0.data(as: IterationTask.self) }
                    await MainActor.run {
                        self.tasks = tasks
                        self.updateFilteredTasks()
                    }
                }
            }
    }

    private func updateFilteredTasks() {
        activeTasks = tasks.filter { $0.status == .pending || $0.status == .inProgress }
        completedTasks = tasks.filter { $0.status == .completed }
    }

    // MARK: - Data Persistence

    private func saveTask(_ task: IterationTask) async throws {
        let docRef = db.collection("iterationTasks").document(task.id)
        try docRef.setData(from: task)
    }

    private func loadTasks() {
        Task {
            do {
                let snapshot = try await db.collection("iterationTasks")
                    .order(by: "createdAt", descending: true)
                    .getDocuments()

                let loadedTasks = snapshot.documents.compactMap { try? $0.data(as: IterationTask.self) }

                await MainActor.run {
                    self.tasks = loadedTasks
                    self.updateFilteredTasks()
                }
            } catch {
                print("Failed to load tasks: \(error)")
            }
        }
    }

    // MARK: - Task Assignment (Future Enhancement)

    func assignTask(_ taskId: String, to assignee: String) async {
        // Future: Implement task assignment system
        // For now, just update the task with assignee info
        if var task = tasks.first(where: { $0.id == taskId }) {
            task.assignee = assignee
            task.updatedAt = Date()
            await updateTask(task)
        }
    }

    // MARK: - Integration Points

    func linkTaskToFeedback(_ taskId: String, feedbackId: String) async {
        if var task = tasks.first(where: { $0.id == taskId }) {
            task.createdFrom = feedbackId
            task.updatedAt = Date()
            await updateTask(task)
        }
    }

    func markTaskCompleted(_ taskId: String, completionNotes: String? = nil) async {
        if var task = tasks.first(where: { $0.id == taskId }) {
            task.status = .completed
            task.completedAt = Date()
            task.completionNotes = completionNotes
            task.updatedAt = Date()
            await updateTask(task)

            // Track completion
            AnalyticsManager.shared.trackFeatureUsage(feature: "iteration_task_completed", context: task.type.rawValue)
        }
    }

    // MARK: - Cleanup

    func archiveCompletedTasks(olderThan days: Int = 30) async {
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 3600)

        let tasksToArchive = tasks.filter {
            $0.status == .completed && $0.completedAt != nil && $0.completedAt! < cutoffDate
        }

        for task in tasksToArchive {
            do {
                // Move to archive collection
                try await db.collection("archivedTasks").document(task.id).setData(from: task)
                try await db.collection("iterationTasks").document(task.id).delete()

                await MainActor.run {
                    self.tasks.removeAll { $0.id == task.id }
                    self.updateFilteredTasks()
                }
            } catch {
                print("Failed to archive task \(task.id): \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

struct IterationTask: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var type: IterationTaskType
    var priority: IterationPriority
    var status: IterationStatus
    var createdFrom: String? // Feedback response ID
    var userId: String
    var surveyType: String
    var actionableItems: [String]
    var assignee: String?
    var dueDate: Date?
    var completedAt: Date?
    var completionNotes: String?
    var createdAt: Date
    var updatedAt: Date?

    init(id: String, title: String, description: String, type: IterationTaskType, priority: IterationPriority, status: IterationStatus, createdFrom: String?, userId: String, surveyType: String, actionableItems: [String], createdAt: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.priority = priority
        self.status = status
        self.createdFrom = createdFrom
        self.userId = userId
        self.surveyType = surveyType
        self.actionableItems = actionableItems
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
}

enum IterationTaskType: String, Codable, CaseIterable {
    case featureRequest = "feature_request"
    case bugFix = "bug_fix"
    case uxImprovement = "ux_improvement"
    case performance = "performance"
    case urgent = "urgent"
    case maintenance = "maintenance"

    var displayName: String {
        switch self {
        case .featureRequest: return "Feature Request"
        case .bugFix: return "Bug Fix"
        case .uxImprovement: return "UX Improvement"
        case .performance: return "Performance"
        case .urgent: return "Urgent"
        case .maintenance: return "Maintenance"
        }
    }
}

enum IterationPriority: String, Codable, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"

    var color: String {
        switch self {
        case .critical: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "green"
        }
    }
}

enum IterationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

struct TaskMetrics {
    let totalTasks: Int
    let completedTasks: Int
    let pendingTasks: Int
    let inProgressTasks: Int
    let averageCompletionTime: TimeInterval?
    let overdueTasks: Int

    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}

// MARK: - SwiftUI Integration

struct IterationDashboardView: View {
    @ObservedObject var tracker = IterationTracker.shared
    @State private var selectedFilter: IterationStatus = .pending

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundGradients.heroGradient
                    .ignoresSafeArea()

                VStack(spacing: SpacingSystem.lg) {
                    // Metrics Header
                    TaskMetricsView(metrics: tracker.getTaskMetrics())

                    // Filter Picker
                    Picker("Status", selection: $selectedFilter) {
                        ForEach(IterationStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, SpacingSystem.lg)

                    // Task List
                    ScrollView {
                        VStack(spacing: SpacingSystem.md) {
                            let filteredTasks = tracker.getTasks(status: selectedFilter)
                            ForEach(filteredTasks) { task in
                                TaskCardView(task: task)
                            }
                        }
                        .padding(.horizontal, SpacingSystem.lg)
                    }
                }
            }
            .navigationTitle("Iteration Tracker")
        }
    }
}

struct TaskMetricsView: View {
    let metrics: TaskMetrics

    var body: some View {
        VStack(spacing: SpacingSystem.sm) {
            HStack(spacing: SpacingSystem.lg) {
                MetricCard(title: "Total", value: "\(metrics.totalTasks)", color: .blue)
                MetricCard(title: "Completed", value: "\(metrics.completedTasks)", color: .green)
                MetricCard(title: "Pending", value: "\(metrics.pendingTasks)", color: .orange)
            }

            HStack(spacing: SpacingSystem.lg) {
                MetricCard(title: "In Progress", value: "\(metrics.inProgressTasks)", color: .purple)
                MetricCard(title: "Completion Rate", value: "\(Int(metrics.completionRate * 100))%", color: .teal)
                MetricCard(title: "Overdue", value: "\(metrics.overdueTasks)", color: .red)
            }
        }
        .padding(.horizontal, SpacingSystem.lg)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: SpacingSystem.xs) {
            Text(title)
                .font(TypographySystem.captionMedium)
                .foregroundColor(AdaptiveColors.secondaryText)

            Text(value)
                .font(TypographySystem.headlineMedium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingSystem.md)
        .background(AdaptiveColors.glassBackground)
        .cornerRadius(12)
    }
}

struct TaskCardView: View {
    let task: IterationTask

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingSystem.sm) {
            HStack {
                Text(task.title)
                    .font(TypographySystem.headlineSmall)
                    .foregroundColor(AdaptiveColors.primaryText)

                Spacer()

                PriorityBadge(priority: task.priority)
            }

            Text(task.description)
                .font(TypographySystem.bodyMedium)
                .foregroundColor(AdaptiveColors.secondaryText)
                .lineLimit(2)

            HStack {
                Text(task.type.displayName)
                    .font(TypographySystem.captionMedium)
                    .foregroundColor(AdaptiveColors.secondaryText)

                Spacer()

                Text(task.status.displayName)
                    .font(TypographySystem.captionMedium)
                    .foregroundColor(statusColor)
            }
        }
        .padding(SpacingSystem.md)
        .background(AdaptiveColors.glassBackground)
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch task.status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
}

struct PriorityBadge: View {
    let priority: IterationPriority

    var body: some View {
        Text(priority.rawValue.uppercased())
            .font(TypographySystem.captionBold)
            .foregroundColor(.white)
            .padding(.horizontal, SpacingSystem.xs)
            .padding(.vertical, SpacingSystem.xxs)
            .background(priorityColor)
            .cornerRadius(6)
    }

    private var priorityColor: Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}