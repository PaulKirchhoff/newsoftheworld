import SwiftUI

struct TickerPanelView: View {
    @Bindable var viewModel: TickerViewModel

    private let cornerRadius: CGFloat = 10

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            TickerMessageView(
                systemImage: "antenna.radiowaves.left.and.right.slash",
                text: Text("ticker.state.noSources"),
                fontSize: CGFloat(viewModel.fontSize)
            )
        case .loading:
            TickerMessageView(
                systemImage: "arrow.triangle.2.circlepath",
                text: Text("ticker.state.loading"),
                fontSize: CGFloat(viewModel.fontSize)
            )
        case .empty:
            TickerMessageView(
                systemImage: "tray",
                text: Text("ticker.state.empty"),
                fontSize: CGFloat(viewModel.fontSize)
            )
        case .error(let message):
            TickerMessageView(
                systemImage: "exclamationmark.triangle",
                text: Text(verbatim: message),
                fontSize: CGFloat(viewModel.fontSize),
                tint: .red
            )
        case .loaded(let items):
            TickerView(
                items: items,
                speed: viewModel.speed,
                separator: viewModel.separator,
                fontSize: CGFloat(viewModel.fontSize)
            )
        }
    }
}

private struct TickerMessageView: View {
    let systemImage: String
    let text: Text
    let fontSize: CGFloat
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            text
                .font(.system(size: fontSize, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
