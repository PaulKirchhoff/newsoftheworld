import SwiftUI

struct SourceDraft {
    var name: String
    var type: SourceType
    var url: URL
    var isEnabled: Bool
    var apiKeyInput: String
    var apiKeyUpdate: APIKeyUpdate
}

struct SourceFormSheet: View {
    enum Mode: Identifiable, Equatable {
        case add
        case edit(NewsSource)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let source): "edit.\(source.id.uuidString)"
            }
        }
    }

    let mode: Mode
    let onCommit: (SourceDraft) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var type: SourceType = .rss
    @State private var urlString: String = ""
    @State private var isEnabled: Bool = true
    @State private var apiKey: String = ""
    @State private var clearStoredKey: Bool = false
    @State private var hasExistingKey: Bool = false

    private var trimmedURL: String { urlString.trimmingCharacters(in: .whitespaces) }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var parsedURL: URL? { URL(string: trimmedURL).flatMap { $0.scheme == nil ? nil : $0 } }
    private var isValid: Bool { !trimmedName.isEmpty && parsedURL != nil }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Quelle") {
                    TextField("Name", text: $name)
                    Picker("Typ", selection: $type) {
                        ForEach(SourceType.allCases, id: \.self) { t in
                            Text(t.localizedName).tag(t)
                        }
                    }
                    TextField("URL", text: $urlString, prompt: Text("https://example.com/feed"))
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                    Toggle("Aktiv", isOn: $isEnabled)
                }

                Section("API-Key") {
                    if hasExistingKey && !clearStoredKey {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("API-Key ist gespeichert.")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Entfernen", role: .destructive) {
                                clearStoredKey = true
                                apiKey = ""
                            }
                        }
                    }
                    SecureField(
                        hasExistingKey && !clearStoredKey ? "Neuen API-Key eingeben (ersetzt gespeicherten)" : "API-Key (optional)",
                        text: $apiKey
                    )
                    if clearStoredKey {
                        Text("Gespeicherter API-Key wird beim Speichern entfernt.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Spacer()
                Button("Abbrechen", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Speichern") { commit() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding(12)
        }
        .frame(width: 460, height: 420)
        .onAppear(perform: prefill)
    }

    private func prefill() {
        if case .edit(let source) = mode {
            name = source.name
            type = source.type
            urlString = source.endpointURL.absoluteString
            isEnabled = source.isEnabled
            hasExistingKey = source.hasAPIKey
        }
    }

    private func commit() {
        guard let url = parsedURL else { return }
        let update: APIKeyUpdate
        switch mode {
        case .add:
            update = apiKey.isEmpty ? .unchanged : .replaced(apiKey)
        case .edit:
            if clearStoredKey {
                update = .cleared
            } else if !apiKey.isEmpty {
                update = .replaced(apiKey)
            } else {
                update = .unchanged
            }
        }
        onCommit(SourceDraft(
            name: trimmedName,
            type: type,
            url: url,
            isEnabled: isEnabled,
            apiKeyInput: apiKey,
            apiKeyUpdate: update
        ))
    }
}
