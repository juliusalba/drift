import Foundation

// MARK: - Core Models

struct DriftRun: Codable, Identifiable {
    let id: String
    let projectName: String
    let timestamp: String
    let summary: RunSummary
    let screens: [DriftScreen]
    let iterations: [Iteration]

    enum CodingKeys: String, CodingKey {
        case id
        case projectName = "project_name"
        case timestamp
        case summary
        case screens
        case iterations
    }
}

struct RunSummary: Codable {
    let overallScore: Double
    let totalScreens: Int
    let passingScreens: Int
    let reviewScreens: Int
    let criticalIssues: Int
    let majorIssues: Int
    let autoFixed: Int
    let totalIterations: Int
    let status: RunStatus

    enum CodingKeys: String, CodingKey {
        case overallScore = "overall_score"
        case totalScreens = "total_screens"
        case passingScreens = "passing_screens"
        case reviewScreens = "review_screens"
        case criticalIssues = "critical_issues"
        case majorIssues = "major_issues"
        case autoFixed = "auto_fixed"
        case totalIterations = "total_iterations"
        case status
    }
}

enum RunStatus: String, Codable {
    case pass
    case acceptable
    case needsReview = "needs_review"
    case fail
    case inProgress = "in_progress"
    case unknown
}

struct DriftScreen: Codable, Identifiable {
    var id: String { name }
    let name: String
    let score: Double
    let filePath: String
    let discrepancies: [Discrepancy]
    var screenshotPath: String? = nil
    var designPath: String? = nil

    enum CodingKeys: String, CodingKey {
        case name
        case score
        case filePath = "file_path"
        case discrepancies
        case screenshotPath = "screenshot_path"
        case designPath = "design_path"
    }
}

struct Discrepancy: Codable, Identifiable {
    var id: String { "\(element)-\(type)-\(severity)" }
    let type: DiscrepancyType
    let severity: Severity
    let element: String
    let expected: String
    let actual: String
    var fixHint: String? = nil
    let status: FixStatus
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case type, severity, element, expected, actual
        case fixHint = "fix_hint"
        case status, confidence
    }
}

enum DiscrepancyType: String, Codable {
    case color, spacing, typography, layout
    case missingElement = "missing_element"
    case extraElement = "extra_element"
    case alignment, content
}

enum Severity: String, Codable, CaseIterable {
    case critical, major, minor, cosmetic
}

enum FixStatus: String, Codable {
    case open, fixed
    case wontFix = "wont_fix"
}

struct Iteration: Codable, Identifiable {
    var id: Int { number }
    let number: Int
    let score: Double
    let delta: Double
    let fixed: Int
    let regressions: Int
    var timestamp: String? = nil
}

struct RunIndexEntry: Codable, Identifiable {
    let id: String
    let projectName: String
    let timestamp: String
    let overallScore: Double
    let totalScreens: Int
    let passingScreens: Int
    let status: String
    let iterations: Int

    enum CodingKeys: String, CodingKey {
        case id
        case projectName = "project_name"
        case timestamp
        case overallScore = "overall_score"
        case totalScreens = "total_screens"
        case passingScreens = "passing_screens"
        case status
        case iterations
    }
}

struct RunIndex: Codable {
    let runs: [RunIndexEntry]
}

// MARK: - Settings

struct DriftSettings: Codable {
    var figmaFileId: String = ""
    var passThreshold: Double = 0.9
    var maxIterations: Int = 5
    var simulatorDevice: String = "iPhone 16 Pro"
    var watchedProjectPath: String = ""
    var autoRunOnBuild: Bool = true
}

// MARK: - Helpers

extension Double {
    var scoreFormatted: String {
        "\(Int(self * 100))%"
    }

    var scoreColor: ScoreLevel {
        if self >= 0.9 { return .pass }
        if self >= 0.7 { return .warning }
        return .fail
    }
}

enum ScoreLevel {
    case pass, warning, fail
}
