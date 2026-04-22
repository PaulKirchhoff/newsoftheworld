import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem { Label("tab.general", systemImage: "gearshape") }

            SourcesSettingsView(viewModel: viewModel)
                .tabItem { Label("tab.sources", systemImage: "antenna.radiowaves.left.and.right") }
        }
        .padding(16)
        .frame(minWidth: 560, minHeight: 500)
    }
}

private struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("section.appearance") {
                Picker("appearance.mode", selection: appearanceBinding) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(appearanceLabel(for: mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("section.ticker") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("ticker.speed")
                        Spacer()
                        Text(verbatim: "\(Int(viewModel.appSettings.tickerSpeed)) pt/s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: tickerSpeedBinding,
                        in: 20...200,
                        step: 10
                    ) {
                        Text("ticker.speed")
                    } minimumValueLabel: {
                        Text("ticker.slow").font(.caption).foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("ticker.fast").font(.caption).foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("ticker.fontSize")
                        Spacer()
                        Text(verbatim: "\(Int(viewModel.appSettings.tickerFontSize)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: tickerFontSizeBinding,
                        in: 11...22,
                        step: 1
                    ) {
                        Text("ticker.fontSize")
                    } minimumValueLabel: {
                        Text(verbatim: "A").font(.caption).foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text(verbatim: "A").font(.title3).foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("ticker.width")
                        Spacer()
                        Text(verbatim: "\(Int(viewModel.appSettings.tickerPanelWidth)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: tickerPanelWidthBinding,
                        in: 320...1200,
                        step: 20
                    ) {
                        Text("ticker.width")
                    } minimumValueLabel: {
                        Text("ticker.narrow").font(.caption).foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("ticker.wide").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section("section.start") {
                Toggle("start.autoShowTicker", isOn: autoShowBinding)
                Toggle("start.launchAtLogin", isOn: launchAtLoginBinding)
                    .disabled(viewModel.launchAtLoginState == .notAvailable)
                if viewModel.launchAtLoginState == .requiresApproval {
                    Text("start.launchAtLogin.requiresApproval")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("section.language") {
                Picker(selection: languageBinding) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(languageLabel(for: language)).tag(language)
                    }
                } label: {
                    Text("section.language")
                }
                .labelsHidden()
            }
        }
        .formStyle(.grouped)
        .alert(
            "language.restart.title",
            isPresented: $viewModel.languageRestartPromptVisible
        ) {
            Button("language.restart.relaunch") { viewModel.relaunchForLanguageChange() }
            Button("language.restart.later", role: .cancel) {
                viewModel.languageRestartPromptVisible = false
            }
        } message: {
            Text("language.restart.message")
        }
    }

    private func appearanceLabel(for mode: AppearanceMode) -> LocalizedStringKey {
        switch mode {
        case .system: "appearance.system"
        case .light:  "appearance.light"
        case .dark:   "appearance.dark"
        }
    }

    private func languageLabel(for language: AppLanguage) -> String {
        switch language {
        case .system: String(localized: "language.system")
        case .german, .english, .french, .spanish: language.displayName
        }
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(
            get: { viewModel.appSettings.appearance },
            set: {
                viewModel.appSettings.appearance = $0
                viewModel.persistSettings()
            }
        )
    }

    private var autoShowBinding: Binding<Bool> {
        Binding(
            get: { viewModel.appSettings.autoShowTickerOnLaunch },
            set: {
                viewModel.appSettings.autoShowTickerOnLaunch = $0
                viewModel.persistSettings()
            }
        )
    }

    private var tickerSpeedBinding: Binding<Double> {
        Binding(
            get: { viewModel.appSettings.tickerSpeed },
            set: {
                viewModel.appSettings.tickerSpeed = $0
                viewModel.persistSettings()
            }
        )
    }

    private var tickerFontSizeBinding: Binding<Double> {
        Binding(
            get: { viewModel.appSettings.tickerFontSize },
            set: {
                viewModel.appSettings.tickerFontSize = $0
                viewModel.persistSettings()
            }
        )
    }

    private var tickerPanelWidthBinding: Binding<Double> {
        Binding(
            get: { viewModel.appSettings.tickerPanelWidth },
            set: {
                viewModel.appSettings.tickerPanelWidth = $0
                viewModel.persistSettings()
            }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { viewModel.launchAtLoginState == .enabled },
            set: { viewModel.setLaunchAtLogin($0) }
        )
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { viewModel.appSettings.language },
            set: { viewModel.setLanguage($0) }
        )
    }
}

private struct SourcesSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var editing: SourceFormSheet.Mode?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.sources.isEmpty {
                emptyState
            } else {
                list
            }
            Divider()
            toolbar
        }
        .sheet(item: $editing) { mode in
            SourceFormSheet(
                mode: mode,
                onTest: { draft in
                    let existingID: UUID? = {
                        if case .edit(let s) = mode { return s.id }
                        return nil
                    }()
                    return await viewModel.testSource(
                        name: draft.name,
                        type: draft.type,
                        url: draft.url,
                        enteredAPIKey: draft.apiKeyInput,
                        existingSourceID: existingID
                    )
                },
                onCommit: { draft in
                    switch mode {
                    case .add:
                        viewModel.addSource(
                            name: draft.name,
                            type: draft.type,
                            url: draft.url,
                            apiKey: draft.apiKeyInput.isEmpty ? nil : draft.apiKeyInput,
                            isEnabled: draft.isEnabled,
                            refreshIntervalSeconds: draft.refreshIntervalSeconds
                        )
                    case .edit(let source):
                        viewModel.updateSource(
                            id: source.id,
                            name: draft.name,
                            type: draft.type,
                            url: draft.url,
                            isEnabled: draft.isEnabled,
                            refreshIntervalSeconds: draft.refreshIntervalSeconds,
                            apiKeyUpdate: draft.apiKeyUpdate
                        )
                    }
                    editing = nil
                },
                onCancel: { editing = nil }
            )
        }
        .alert(
            "alert.error.title",
            isPresented: Binding(
                get: { viewModel.lastError != nil },
                set: { if !$0 { viewModel.lastError = nil } }
            ),
            presenting: viewModel.lastError
        ) { _ in
            Button("common.ok", role: .cancel) { viewModel.lastError = nil }
        } message: { message in
            Text(message)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("sources.empty.title")
                .font(.headline)
            Text("sources.empty.message")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var list: some View {
        List {
            ForEach(viewModel.sources) { source in
                SourceRow(
                    source: source,
                    status: viewModel.statusStore.statuses[source.id],
                    onEnabledToggle: { enabled in
                        viewModel.setSourceEnabled(id: source.id, enabled: enabled)
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { editing = .edit(source) }
                .contextMenu {
                    Button("sources.action.edit") { editing = .edit(source) }
                    Button("sources.action.refreshNow") {
                        viewModel.refreshNow(sourceID: source.id)
                    }
                    .disabled(!source.isEnabled)
                    Divider()
                    Button("sources.action.remove", role: .destructive) {
                        viewModel.deleteSource(id: source.id)
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    private var toolbar: some View {
        HStack {
            Button {
                editing = .add
            } label: {
                Label("sources.add", systemImage: "plus")
            }
            Spacer()
        }
        .padding(8)
    }
}

private struct SourceRow: View {
    let source: NewsSource
    let status: SourceFetchStatus?
    let onEnabledToggle: (Bool) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: source.name)
                    .font(.body)
                Text(verbatim: source.endpointURL.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                statusLine
            }
            Spacer()
            badges
            Toggle(
                "sourceForm.enabled",
                isOn: Binding(
                    get: { source.isEnabled },
                    set: { onEnabledToggle($0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        if !source.isEnabled { return "pause.circle" }
        if status?.lastErrorMessage != nil { return "exclamationmark.triangle" }
        return "dot.radiowaves.left.and.right"
    }

    private var iconColor: Color {
        if !source.isEnabled { return .secondary }
        if status?.lastErrorMessage != nil { return .red }
        return .accentColor
    }

    @ViewBuilder
    private var statusLine: some View {
        if !source.isEnabled {
            Text("sources.status.disabled")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else if let status {
            if let error = status.lastErrorMessage {
                Text("sources.status.errorPrefix \(error)")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else if let last = status.lastFetchAt {
                HStack(spacing: 6) {
                    Text("sources.status.updatedAgo \(last, style: .relative)")
                    Text(verbatim: "·")
                    Text("sources.status.itemCount \(status.lastItemCount)")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            } else {
                Text("sources.status.loading")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("sources.status.notFetched")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var badges: some View {
        HStack(spacing: 6) {
            Text(verbatim: source.type.localizedName)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15), in: Capsule())
            if source.hasAPIKey {
                Image(systemName: "key.fill")
                    .foregroundStyle(.secondary)
                    .help(Text("sources.storedKeyHint"))
            }
        }
    }
}
