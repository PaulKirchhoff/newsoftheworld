import SwiftUI

struct SourceDraft {
    var name: String
    var type: SourceType
    var url: URL
    var isEnabled: Bool
    var refreshIntervalSeconds: Int
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
    let onTest: (SourceDraft) async -> SourceTestResult
    let onCommit: (SourceDraft) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var type: SourceType = .rss
    @State private var urlString: String = ""
    @State private var isEnabled: Bool = true
    @State private var refreshIntervalMinutes: Int = 5
    @State private var apiKey: String = ""
    @State private var clearStoredKey: Bool = false
    @State private var hasExistingKey: Bool = false

    @State private var testState: TestState = .idle

    private enum TestState: Equatable {
        case idle
        case running
        case success(count: Int)
        case failure(String)
    }

    private var trimmedURL: String { urlString.trimmingCharacters(in: .whitespaces) }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var parsedURL: URL? { URL(string: trimmedURL).flatMap { $0.scheme == nil ? nil : $0 } }
    private var isValid: Bool { !trimmedName.isEmpty && parsedURL != nil }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("sourceForm.section.source") {
                    TextField("sourceForm.name", text: $name)
                    Picker("sourceForm.type", selection: $type) {
                        ForEach(SourceType.allCases, id: \.self) { t in
                            Text(verbatim: t.localizedName).tag(t)
                        }
                    }
                    TextField(
                        "sourceForm.url",
                        text: $urlString,
                        prompt: Text("sourceForm.urlPrompt")
                    )
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    Toggle("sourceForm.enabled", isOn: $isEnabled)
                    Stepper(
                        "sourceForm.interval \(refreshIntervalMinutes)",
                        value: $refreshIntervalMinutes,
                        in: 1...60
                    )
                }

                Section("sourceForm.section.apiKey") {
                    if hasExistingKey && !clearStoredKey {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("sourceForm.apiKey.stored")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("sourceForm.apiKey.remove", role: .destructive) {
                                clearStoredKey = true
                                apiKey = ""
                            }
                        }
                    }
                    SecureField(
                        apiKeyPrompt,
                        text: $apiKey
                    )
                    if clearStoredKey {
                        Text("sourceForm.apiKey.willClear")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("sourceForm.section.test") {
                    HStack(spacing: 8) {
                        Button {
                            runTest()
                        } label: {
                            if case .running = testState {
                                ProgressView().controlSize(.small)
                            } else {
                                Text("sourceForm.test.button")
                            }
                        }
                        .disabled(!isValid || testState == .running)

                        testResultView
                        Spacer()
                    }
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Spacer()
                Button("common.cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("common.save") { commit() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding(12)
        }
        .frame(width: 480, height: 520)
        .onAppear(perform: prefill)
    }

    private var apiKeyPrompt: LocalizedStringKey {
        hasExistingKey && !clearStoredKey ? "sourceForm.apiKey.replace" : "sourceForm.apiKey.optional"
    }

    @ViewBuilder
    private var testResultView: some View {
        switch testState {
        case .idle:
            EmptyView()
        case .running:
            Text("sourceForm.test.running")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .success(let count):
            Label {
                Text("sourceForm.test.success \(count)")
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
            .font(.caption)
            .foregroundStyle(.green)
        case .failure(let message):
            Label {
                Text(verbatim: message)
            } icon: {
                Image(systemName: "xmark.octagon.fill")
            }
            .font(.caption)
            .foregroundStyle(.red)
            .lineLimit(2)
        }
    }

    private func prefill() {
        if case .edit(let source) = mode {
            name = source.name
            type = source.type
            urlString = source.endpointURL.absoluteString
            isEnabled = source.isEnabled
            refreshIntervalMinutes = max(1, min(60, source.refreshIntervalSeconds / 60))
            hasExistingKey = source.hasAPIKey
        }
    }

    private func runTest() {
        guard let url = parsedURL else { return }
        let draft = currentDraft(url: url)
        testState = .running
        Task { @MainActor in
            let result = await onTest(draft)
            switch result {
            case .success(let count): testState = .success(count: count)
            case .failure(let message): testState = .failure(message)
            }
        }
    }

    private func commit() {
        guard let url = parsedURL else { return }
        onCommit(currentDraft(url: url))
    }

    private func currentDraft(url: URL) -> SourceDraft {
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
        return SourceDraft(
            name: trimmedName,
            type: type,
            url: url,
            isEnabled: isEnabled,
            refreshIntervalSeconds: refreshIntervalMinutes * 60,
            apiKeyInput: apiKey,
            apiKeyUpdate: update
        )
    }
}
