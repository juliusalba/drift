import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var service: DriftService
    @State private var showSaved = false

    @State private var unsplashKey = ""
    @State private var pexelsKey = ""
    @State private var figmaToken = ""

    @State private var showUnsplash = false
    @State private var showPexels = false
    @State private var showFigma = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 20, weight: .bold))
                    Text("Configure Drift behavior and API connections")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Project
                settingsSection(title: "Project", icon: "folder.fill") {
                    HStack {
                        TextField("Select a project folder...", text: $service.settings.watchedProjectPath)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                        Button("Browse") { selectFolder() }
                            .controlSize(.small)
                    }
                }

                // API Credentials
                settingsSection(title: "API Credentials", icon: "key.fill") {
                    VStack(spacing: 14) {
                        apiKeyRow(
                            name: "Unsplash",
                            description: "Free stock photos for your app screens",
                            linkLabel: "Get free API key at unsplash.com/developers",
                            url: URL(string: "https://unsplash.com/developers")!,
                            icon: "photo.on.rectangle.angled",
                            value: $unsplashKey,
                            isVisible: $showUnsplash
                        )

                        Divider().opacity(0.3)

                        apiKeyRow(
                            name: "Pexels",
                            description: "Alternative stock photo source",
                            linkLabel: "Get free API key at pexels.com/api",
                            url: URL(string: "https://www.pexels.com/api/new/")!,
                            icon: "camera.fill",
                            value: $pexelsKey,
                            isVisible: $showPexels
                        )

                        Divider().opacity(0.3)

                        apiKeyRow(
                            name: "Figma",
                            description: "Access your design files and tokens",
                            linkLabel: "Generate token at figma.com/developers",
                            url: URL(string: "https://www.figma.com/developers/api#access-tokens")!,
                            icon: "paintbrush.fill",
                            value: $figmaToken,
                            isVisible: $showFigma
                        )
                    }
                }

                // Design Source
                settingsSection(title: "Design Source", icon: "paintbrush.pointed.fill") {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Figma File ID", text: $service.settings.figmaFileId)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                        Text("From the Figma URL: figma.com/design/THIS_PART/...")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }

                // Analysis
                settingsSection(title: "Analysis", icon: "wand.and.stars") {
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Pass Threshold")
                                    .font(.system(size: 12))
                                Spacer()
                                Text(service.settings.passThreshold.scoreFormatted)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(thresholdColor)
                            }
                            Slider(value: $service.settings.passThreshold, in: 0.5...1.0, step: 0.05)
                                .tint(thresholdColor)
                        }

                        HStack {
                            Text("Max Iterations")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $service.settings.maxIterations) {
                                ForEach([1, 2, 3, 5, 8, 10], id: \.self) { n in
                                    Text("\(n)").tag(n)
                                }
                            }
                            .frame(width: 80)
                        }
                    }
                }

                // Simulator
                settingsSection(title: "Simulator", icon: "iphone") {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Device")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $service.settings.simulatorDevice) {
                                ForEach(devices, id: \.self) { device in
                                    Text(device).tag(device)
                                }
                            }
                            .frame(width: 180)
                        }

                        HStack {
                            Toggle(isOn: $service.settings.autoRunOnBuild) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Auto-run on build")
                                        .font(.system(size: 12))
                                    Text("Analyze automatically after each Xcode build")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        }
                    }
                }

                // Connection Status
                settingsSection(title: "Connection Status", icon: "link") {
                    VStack(spacing: 6) {
                        connectionRow("Unsplash", connected: !unsplashKey.isEmpty)
                        connectionRow("Pexels", connected: !pexelsKey.isEmpty)
                        connectionRow("Figma", connected: !figmaToken.isEmpty)
                        connectionRow("Refero MCP", connected: true, note: "Via Claude Code")
                        connectionRow("21st.dev MCP", connected: true, note: "Via Claude Code")
                    }
                }

                // Save / Reset
                HStack {
                    Button {
                        saveAll()
                    } label: {
                        HStack(spacing: 5) {
                            if showSaved {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Saved")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save Settings")
                            }
                        }
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(showSaved ? .green : .blue)

                    Spacer()

                    Button("Reset to Defaults") {
                        let path = service.settings.watchedProjectPath
                        service.settings = DriftSettings()
                        service.settings.watchedProjectPath = path
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .onAppear { loadCredentials() }
    }

    // MARK: - Section Container

    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.05))
            )
        }
        .padding(.horizontal, 24)
    }

    // MARK: - API Key Row (with clickable link)

    private func apiKeyRow(
        name: String,
        description: String,
        linkLabel: String,
        url: URL,
        icon: String,
        value: Binding<String>,
        isVisible: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title + status
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                Text("—")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
                Text(description)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)

                Spacer()

                if !value.wrappedValue.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                }
            }

            // Input field
            HStack(spacing: 4) {
                if isVisible.wrappedValue {
                    TextField("Paste your API key...", text: value)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                } else {
                    SecureField("Paste your API key...", text: value)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                }

                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }

            // Clickable signup link
            Button {
                NSWorkspace.shared.open(url)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 10))
                    Text(linkLabel)
                        .font(.system(size: 10))
                        .underline()
                }
                .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }

    // MARK: - Connection Row

    private func connectionRow(_ name: String, connected: Bool, note: String? = nil) -> some View {
        HStack {
            Circle()
                .fill(connected ? Color.green : Color.primary.opacity(0.15))
                .frame(width: 6, height: 6)
            Text(name)
                .font(.system(size: 11))
            Spacer()
            if let note {
                Text(note)
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
            }
            Text(connected ? "Connected" : "Not configured")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(connected ? .green : .gray)
        }
    }

    // MARK: - Actions

    private func loadCredentials() {
        unsplashKey = KeychainService.read(key: .unsplashAccessKey) ?? ""
        pexelsKey = KeychainService.read(key: .pexelsApiKey) ?? ""
        figmaToken = KeychainService.read(key: .figmaPersonalToken) ?? ""
    }

    private func saveAll() {
        if !unsplashKey.isEmpty {
            _ = KeychainService.save(key: .unsplashAccessKey, value: unsplashKey)
        } else {
            KeychainService.delete(key: .unsplashAccessKey)
        }

        if !pexelsKey.isEmpty {
            _ = KeychainService.save(key: .pexelsApiKey, value: pexelsKey)
        } else {
            KeychainService.delete(key: .pexelsApiKey)
        }

        if !figmaToken.isEmpty {
            _ = KeychainService.save(key: .figmaPersonalToken, value: figmaToken)
        } else {
            KeychainService.delete(key: .figmaPersonalToken)
        }

        _ = KeychainService.exportForScripts()
        service.saveSettings()

        showSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSaved = false
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select your iOS project folder"
        panel.prompt = "Select"
        if panel.runModal() == .OK, let url = panel.url {
            service.setProjectPath(url.path)
        }
    }

    private var thresholdColor: Color {
        switch service.settings.passThreshold.scoreColor {
        case .pass: return .green
        case .warning: return .yellow
        case .fail: return .red
        }
    }

    private let devices = [
        "iPhone 16 Pro",
        "iPhone 16 Pro Max",
        "iPhone 16",
        "iPhone 15 Pro",
        "iPhone SE",
    ]
}
