import Foundation

/// Adds any .swift files on disk that are missing from the first Xcode target in a project.
/// Runs inline Ruby against the `xcodeproj` gem so it works for any project without
/// requiring the user to drop a script in.
@MainActor
final class XcodeSync: ObservableObject {
    @Published var isRunning = false
    @Published var log: String = ""
    @Published var lastResult: Result?

    struct Result {
        let added: [String]
        let skipped: Int
        let projectName: String
        var didChange: Bool { !added.isEmpty }
    }

    enum Failure: Error, LocalizedError {
        case noProject
        case rubyMissing
        case gemMissing
        case scriptFailed(String)
        var errorDescription: String? {
            switch self {
            case .noProject:  "No .xcodeproj found in the project directory."
            case .rubyMissing: "Ruby not found on PATH."
            case .gemMissing:  "`xcodeproj` gem not installed. Run: gem install --user-install xcodeproj"
            case .scriptFailed(let s): "Sync failed: \(s.prefix(200))"
            }
        }
    }

    /// Checks how many .swift files exist on disk but are missing from the pbxproj text.
    /// Fast heuristic — doesn't need ruby.
    static func missingFileCount(in projectDir: URL) -> Int {
        guard let pbx = findPbxproj(in: projectDir),
              let text = try? String(contentsOf: pbx, encoding: .utf8) else { return 0 }
        let swiftFiles = allSwiftFilenames(in: projectDir)
        return swiftFiles.filter { !text.contains($0) }.count
    }

    func sync(projectDir: URL) async throws {
        guard let pbx = Self.findPbxproj(in: projectDir) else { throw Failure.noProject }
        guard let ruby = Self.findRuby() else { throw Failure.rubyMissing }

        isRunning = true
        log = ""
        defer { isRunning = false }

        append("▶ sync Xcode project: \(pbx.deletingLastPathComponent().lastPathComponent)\n")

        // Write the generic sync script to a temp file.
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("drift-xcode-sync-\(UUID().uuidString.prefix(6)).rb")
        try Self.rubyScript.write(to: scriptURL, atomically: true, encoding: .utf8)

        let output = try await runScript(
            ruby: ruby,
            script: scriptURL,
            projectPath: pbx.deletingLastPathComponent().path
        )
        append(output)

        // Parse summary lines the script emits.
        let added = output
            .components(separatedBy: "\n")
            .filter { $0.contains("+ ") && !$0.contains("Added:") }
            .map { $0.replacingOccurrences(of: "    + ", with: "").trimmingCharacters(in: .whitespaces) }
        let skipped = output
            .components(separatedBy: "\n")
            .first(where: { $0.contains("Skipped") })
            .flatMap { $0.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) }
            .flatMap(Int.init) ?? 0
        lastResult = Result(
            added: added,
            skipped: skipped,
            projectName: pbx.deletingLastPathComponent().lastPathComponent
        )
    }

    private func runScript(ruby: String, script: URL, projectPath: String) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: ruby)
            task.arguments = [script.path, projectPath]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            task.terminationHandler = { p in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let out = String(data: data, encoding: .utf8) ?? ""
                if p.terminationStatus == 0 { cont.resume(returning: out) }
                else {
                    if out.contains("LoadError") || out.contains("xcodeproj") && out.contains("cannot") {
                        cont.resume(throwing: Failure.gemMissing)
                    } else {
                        cont.resume(throwing: Failure.scriptFailed(out))
                    }
                }
            }
            do { try task.run() } catch { cont.resume(throwing: error) }
        }
    }

    private func append(_ s: String) { log += s }

    // MARK: - Static helpers

    private static func findPbxproj(in dir: URL) -> URL? {
        let items = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        if let proj = items.first(where: { $0.pathExtension == "xcodeproj" }) {
            return proj.appendingPathComponent("project.pbxproj")
        }
        // One level deep
        for sub in items where (try? sub.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            let nested = (try? FileManager.default.contentsOfDirectory(at: sub, includingPropertiesForKeys: nil)) ?? []
            if let proj = nested.first(where: { $0.pathExtension == "xcodeproj" }) {
                return proj.appendingPathComponent("project.pbxproj")
            }
        }
        return nil
    }

    private static func allSwiftFilenames(in dir: URL) -> [String] {
        guard let en = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return [] }
        var names: [String] = []
        for case let url as URL in en where url.pathExtension == "swift" {
            names.append(url.lastPathComponent)
        }
        return names
    }

    private static func findRuby() -> String? {
        let candidates = ["/usr/bin/ruby", "/opt/homebrew/bin/ruby", "/usr/local/bin/ruby"]
        for c in candidates where FileManager.default.isExecutableFile(atPath: c) { return c }
        return nil
    }

    // MARK: - Embedded Ruby script

    /// Generic version of sync-xcode.rb that accepts a project directory as argv[0].
    /// Finds the first .xcodeproj, adds missing .swift files under it to the first target,
    /// preserving the repo layout (files go into the group matching their directory name).
    private static let rubyScript: String = #"""
    #!/usr/bin/env ruby
    require "xcodeproj"
    require "pathname"
    require "set"

    ROOT = Pathname(ARGV[0] || Dir.pwd).expand_path
    proj_path = Dir.glob(ROOT.join("*.xcodeproj")).first
    abort("no .xcodeproj in #{ROOT}") unless proj_path

    project = Xcodeproj::Project.open(proj_path)
    target  = project.targets.first
    abort("no target") unless target

    existing = project.files.map { |f|
      begin
        f.real_path.realpath.to_s
      rescue
        nil
      end
    }.compact.to_set

    added = []
    skipped = 0
    project_name = File.basename(proj_path, ".xcodeproj")

    # Walk .swift under the project directory (excluding build artefacts).
    Dir.glob(ROOT.join("**/*.swift")).sort.each do |swift_path|
      next if swift_path.include?("/.build/") || swift_path.include?("/DerivedData/") || swift_path.include?("/.drift-cache/")
      abs = Pathname(swift_path).realpath.to_s
      next if existing.include?(abs)

      # Place in a group matching the immediate parent directory, or the main target group.
      parent_dir = Pathname(swift_path).parent.basename.to_s
      group = project.main_group[parent_dir] ||
              project.main_group.groups.find { |g| g.display_name == parent_dir } ||
              project.main_group[project_name] ||
              project.main_group
      ref = group.new_reference(swift_path)
      ref.name = File.basename(swift_path)
      target.add_file_references([ref])
      added << File.basename(swift_path)
    end
    skipped = existing.size

    project.save
    puts "----------------------------------------"
    puts "Drift Xcode sync complete"
    puts "  Added:   #{added.length} item(s)"
    added.each { |a| puts "    + #{a}" }
    puts "  Skipped: #{skipped}"
    puts "----------------------------------------"
    """#
}
