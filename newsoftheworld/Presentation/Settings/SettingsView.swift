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
        .frame(minWidth: 540, minHeight: 420)
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

            Section("Start") {
                Toggle("Ticker beim Start automatisch anzeigen", isOn: autoShowBinding)
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
                onCommit: { draft in
                    switch mode {
                    case .add:
                        viewModel.addSource(
                            name: draft.name,
                            type: draft.type,
                            url: draft.url,
                            apiKey: draft.apiKeyInput.isEmpty ? nil : draft.apiKeyInput,
                            isEnabled: draft.isEnabled
                        )
                    case .edit(let source):
                        viewModel.updateSource(
                            id: source.id,
                            name: draft.name,
                            type: draft.type,
                            url: draft.url,
                            isEnabled: draft.isEnabled,
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
                SourceRow(source: source)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { editing = .edit(source) }
                    .contextMenu {
                        Button("Bearbeiten") { editing = .edit(source) }
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: source.isEnabled ? "dot.radiowaves.left.and.right" : "pause.circle")
                .foregroundStyle(source.isEnabled ? Color.accentColor : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(source.name)
                    .font(.body)
                Text(source.endpointURL.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
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
        .padding(.vertical, 4)
    }
}
