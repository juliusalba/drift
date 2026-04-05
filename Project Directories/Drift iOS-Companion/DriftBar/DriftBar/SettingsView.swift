import SwiftUI

struct SettingsView: View {
    @ObservedObject var service: DriftService
    @State private var showSaved = false

    // Credential fields (loaded from Keychain on appear)
    @State private var unsplashKey = ""
    @State private var pexelsKey = ""
    @State private var figmaToken = ""

    // Visibility toggles
    @State private var showUnsplash = false
    @State private var showPexels = false
    @State private var showFigma = false

    var body: some View {
        Form {
            // Project
            Section {
                HStack {
                    TextField("Project folder", text: $service.settings.watchedProjectPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    Button("Browse") { selectFolder() }
                }
            } header: {
                Label("Project", systemImage: "folder")
            } footer: {
                Text("Path to your iOS project root containing the Xcode project.")
            }

            // API Credentials
            Section {
                credentialRow(
                    key: .unsplashAccessKey,
                    value: $unsplashKey,
                    isVisible: $showUnsplash,
                    icon: "photo.on.rectangle"
                )
                credentialRow(
                    key: .pexelsApiKey,
                    value: $pexelsKey,
                    isVisible: $showPexels,
                    icon: "camera"
                )
                credentialRow(
                    key: .figmaPersonalToken,
                    value: $figmaToken,
                    isVisible: $showFigma,
                    icon: "paintbrush"
                )
            } header: {
                Label("API Credentials", systemImage: "key")
            } footer: {
                Text("Stored securely in macOS Keychain. Click the link icon to sign up for a free key.")
            }

            // Design Source
            Section {
                TextField("Figma File ID", text: $service.settings.figmaFileId)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
            } header: {
                Label("Design Source", systemImage: "paintbrush.pointed")
            } footer: {
                Text("From the Figma URL: figma.com/design/THIS_PART/...")
            }

            // Analysis
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Pass Threshold")
                            Spacer()
                            Text(service.settings.passThreshold.scoreFormatted)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(thresholdColor)
                        }
                        Slider(value: $service.settings.passThreshold, in: 0.5...1.0, step: 0.05)
                            .tint(thresholdColor)
                    }

                    Picker("Max Iterations", selection: $service.settings.maxIterations) {
                        ForEach([1, 2, 3, 5, 8, 10], id: \.self) { n in
                            Text("\(n)").tag(n)
                        }
                    }
                }
            } header: {
                Label("Analysis", systemImage: "wand.and.stars")
            }

            // Simulator
            Section {
                Picker("Device", selection: $service.settings.simulatorDevice) {
                    ForEach(devices, id: \.self) { device in
                        Text(device).tag(device)
                    }
                }
                Toggle("Auto-run on build", isOn: $service.settings.autoRunOnBuild)
            } header: {
                Label("Simulator", systemImage: "iphone")
            } footer: {
                Text("When enabled, Drift automatically analyzes after each Xcode build.")
            }

            // Connection Status
            Section {
                connectionRow("Unsplash", connected: KeychainService.hasKey(.unsplashAccessKey))
                connectionRow("Pexels", connected: KeychainService.hasKey(.pexelsApiKey))
                connectionRow("Figma", connected: KeychainService.hasKey(.figmaPersonalToken))
                connectionRow("Refero MCP", connected: true, note: "Via Claude Code")
                connectionRow("21st.dev MCP", connected: true, note: "Via Claude Code")
            } header: {
                Label("Connections", systemImage: "link")
            }

            // Actions
            Section {
                HStack {
                    Button {
                        saveAll()
                    } label: {
                        if showSaved {
                            Label("Saved", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Text("Save Settings")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(showSaved ? .green : .blue)

                    Spacer()

                    Button("Reset to Defaults") {
                        let path = service.settings.watchedProjectPath
                        service.settings = DriftSettings()
                        service.settings.watchedProjectPath = path
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, minHeight: 580)
        .onAppear { loadCredentials() }
    }

    // MARK: - Credential Row

    private func credentialRow(
        key: KeychainService.Key,
        value: Binding<String>,
        isVisible: Binding<Bool>,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(key.displayName)
                    .font(.system(size: 12, weight: .medium))

                Spacer()

                // Status dot
                if KeychainService.hasKey(key) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                }

                // Signup link
                if let url = key.signupURL {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help("Get your API key")
                }
            }

            HStack(spacing: 4) {
                if isVisible.wrappedValue {
                    TextField("Paste key here...", text: value)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                } else {
                    SecureField("Paste key here...", text: value)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                }

                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
            }

            Text(key.helpText)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Connection Row

    private func connectionRow(_ name: String, connected: Bool, note: String? = nil) -> some View {
        HStack {
            Circle()
                .fill(connected ? Color.green : Color.red.opacity(0.6))
                .frame(width: 6, height: 6)
            Text(name)
                .font(.system(size: 12))
            Spacer()
            if let note {
                Text(note)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Text(connected ? "Connected" : "Not configured")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(connected ? .green : .secondary)
        }
    }

    // MARK: - Actions

    private func loadCredentials() {
        unsplashKey = KeychainService.read(key: .unsplashAccessKey) ?? ""
        pexelsKey = KeychainService.read(key: .pexelsApiKey) ?? ""
        figmaToken = KeychainService.read(key: .figmaPersonalToken) ?? ""
    }

    private func saveAll() {
        // Save credentials to Keychain
        if !unsplashKey.isEmpty {
            KeychainService.save(key: .unsplashAccessKey, value: unsplashKey)
        } else {
            KeychainService.delete(key: .unsplashAccessKey)
        }

        if !pexelsKey.isEmpty {
            KeychainService.save(key: .pexelsApiKey, value: pexelsKey)
        } else {
            KeychainService.delete(key: .pexelsApiKey)
        }

        if !figmaToken.isEmpty {
            KeychainService.save(key: .figmaPersonalToken, value: figmaToken)
        } else {
            KeychainService.delete(key: .figmaPersonalToken)
        }

        // Export for CLI scripts
        KeychainService.exportForScripts()

        // Save other settings
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
            service.settings.watchedProjectPath = url.path
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
