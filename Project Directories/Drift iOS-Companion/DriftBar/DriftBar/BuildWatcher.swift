import Foundation
import Combine

/// Watches DerivedData for Xcode build completions and drift-reports for new results.
final class BuildWatcher: ObservableObject {
    @Published var lastBuildTime: Date?
    @Published var lastReportTime: Date?

    private var derivedDataSource: DispatchSourceFileSystemObject?
    private var reportsSource: DispatchSourceFileSystemObject?
    private var derivedDataFD: Int32 = -1
    private var reportsFD: Int32 = -1

    private let onBuildCompleted: () -> Void
    private let onReportsChanged: () -> Void

    init(onBuildCompleted: @escaping () -> Void, onReportsChanged: @escaping () -> Void) {
        self.onBuildCompleted = onBuildCompleted
        self.onReportsChanged = onReportsChanged
    }

    deinit {
        stop()
    }

    // MARK: - DerivedData Watching

    func watchDerivedData() {
        let derivedData = NSHomeDirectory() + "/Library/Developer/Xcode/DerivedData"

        guard FileManager.default.fileExists(atPath: derivedData) else { return }

        derivedDataFD = open(derivedData, O_EVTONLY)
        guard derivedDataFD >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: derivedDataFD,
            eventMask: [.write, .rename],
            queue: .global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            // Debounce: Xcode writes many files during a build.
            // Wait for activity to settle before triggering.
            Thread.sleep(forTimeInterval: 2.0)
            DispatchQueue.main.async {
                self?.lastBuildTime = Date()
                self?.onBuildCompleted()
            }
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.derivedDataFD, fd >= 0 {
                close(fd)
                self?.derivedDataFD = -1
            }
        }

        source.resume()
        derivedDataSource = source
    }

    // MARK: - Reports Directory Watching

    func watchReports(at path: String) {
        stopReportsWatch()

        let reportsPath = (path as NSString).appendingPathComponent("drift-reports")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            atPath: reportsPath,
            withIntermediateDirectories: true
        )

        reportsFD = open(reportsPath, O_EVTONLY)
        guard reportsFD >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: reportsFD,
            eventMask: [.write, .rename],
            queue: .global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            Thread.sleep(forTimeInterval: 1.0)
            DispatchQueue.main.async {
                self?.lastReportTime = Date()
                self?.onReportsChanged()
            }
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.reportsFD, fd >= 0 {
                close(fd)
                self?.reportsFD = -1
            }
        }

        source.resume()
        reportsSource = source
    }

    // MARK: - Lifecycle

    private func stopReportsWatch() {
        reportsSource?.cancel()
        reportsSource = nil
    }

    func stop() {
        derivedDataSource?.cancel()
        derivedDataSource = nil
        stopReportsWatch()
    }
}
