import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem { Label("Allgemein", systemImage: "gearshape") }

            SourcesSettingsView(viewModel: viewModel)
                .tabItem { Label("Quellen", systemImage: "antenna.radiowaves.left.and.right") }
        }
        .padding(16)
        .frame(minWidth: 560, minHeight: 460)
    }
}

private struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Erscheinungsbild") {
                Picker("Modus", selection: appearanceBinding) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Ticker") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Geschwindigkeit")
                        Spacer()
                        Text("\(Int(viewModel.appSettings.tickerSpeed)) pt/s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: tickerSpeedBinding,
                        in: 20...200,
                        step: 10
                    ) {
                        Text("Geschwindigkeit")
                    } minimumValueLabel: {
                        Text("Langsam").font(.caption).foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("Schnell").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Start") {
                Toggle("Ticker beim Start automatisch anzeigen", isOn: autoShowBinding)
                Toggle(
                    "Beim Anmelden starten",
                    isOn: launchAtLoginBinding
                )
                .disabled(viewModel.launchAtLoginState == .notAvailable)
                if viewModel.launchAtLoginState == .requiresApproval {
                    Text("Aktivierung muss in den Systemeinstellungen → Allgemein → Anmeldeobjekte bestätigt werden.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
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

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { viewModel.launchAtLoginState == .enabled },
            set: { viewModel.setLaunchAtLogin($0) }
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
            "Fehler",
            isPresented: Binding(
                get: { viewModel.lastError != nil },
                set: { if !$0 { viewModel.lastError = nil } }
            ),
            presenting: viewModel.lastError
        ) { _ in
            Button("OK", role: .cancel) { viewModel.lastError = nil }
        } message: { message in
            Text(message)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Noch keine Quellen")
                .font(.headline)
            Text("Füge RSS-, Atom- oder JSON-API-Quellen hinzu, um Nachrichten im Ticker anzuzeigen.")
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
                    status: viewModel.statusStore.statuses[source.id]
                )
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { editing = .edit(source) }
                .contextMenu {
                    Button("Bearbeiten") { editing = .edit(source) }
                    Button("Jetzt aktualisieren") {
                        viewModel.refreshNow(sourceID: source.id)
                    }
                    .disabled(!source.isEnabled)
                    Divider()
                    Button("Entfernen", role: .destructive) {
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
                Label("Quelle hinzufügen", systemImage: "plus")
            }
            Spacer()
        }
        .padding(8)
    }
}

private struct SourceRow: View {
    let source: NewsSource
    let status: SourceFetchStatus?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(source.name)
                    .font(.body)
                Text(source.endpointURL.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                statusLine
            }
            Spacer()
            badges
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
            Text("Deaktiviert")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else if let status {
            if let error = status.lastErrorMessage {
                Text("Fehler: \(error)")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else if let last = status.lastFetchAt {
                Text("Aktualisiert \(last, style: .relative) vor · \(status.lastItemCount) Items")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Wird geladen …")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("Noch nicht abgerufen")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var badges: some View {
        HStack(spacing: 6) {
            Text(source.type.localizedName)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15), in: Capsule())
            if source.hasAPIKey {
                Image(systemName: "key.fill")
                    .foregroundStyle(.secondary)
                    .help("API-Key gespeichert")
            }
        }
    }
}
