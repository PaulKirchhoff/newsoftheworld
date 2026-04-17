import SwiftUI

struct TickerPanelView: View {
    @Bindable var viewModel: TickerViewModel

    var body: some View {
        ZStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 520, height: 44)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            TickerMessageView(
                systemImage: "antenna.radiowaves.left.and.right.slash",
                text: "Keine Quellen konfiguriert"
            )
        case .loading:
            TickerMessageView(
                systemImage: "arrow.triangle.2.circlepath",
                text: "Lade Nachrichten …"
            )
        case .empty:
            TickerMessageView(
                systemImage: "tray",
                text: "Keine Nachrichten"
            )
        case .error(let message):
            TickerMessageView(
                systemImage: "exclamationmark.triangle",
                text: message,
                tint: .red
            )
        case .loaded(let items):
            TickerView(
                items: items,
                speed: viewModel.speed,
                separator: viewModel.separator
            )
        }
    }
}

private struct TickerMessageView: View {
    let systemImage: String
    let text: String
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(text)
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
    }
}
