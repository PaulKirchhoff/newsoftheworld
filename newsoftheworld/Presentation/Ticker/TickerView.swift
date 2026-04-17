import SwiftUI

struct TickerView: View {
    let items: [NewsItem]
    let speed: Double
    let separator: String

    @State private var contentWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var animationID = UUID()

    var body: some View {
        GeometryReader { geo in
            let viewWidth = geo.size.width

            tickerRow
                .fixedSize(horizontal: true, vertical: false)
                .background(
                    GeometryReader { contentGeo in
                        Color.clear.preference(
                            key: TickerContentWidthKey.self,
                            value: contentGeo.size.width
                        )
                    }
                )
                .offset(x: offset)
                .frame(width: viewWidth, alignment: .leading)
                .clipped()
                .onPreferenceChange(TickerContentWidthKey.self) { width in
                    guard width != contentWidth else { return }
                    contentWidth = width
                    restartAnimation(viewWidth: viewWidth)
                }
                .onChange(of: viewWidth) { _, newValue in
                    restartAnimation(viewWidth: newValue)
                }
                .onChange(of: speed) { _, _ in
                    restartAnimation(viewWidth: viewWidth)
                }
                .onChange(of: items) { _, _ in
                    animationID = UUID()
                }
                .id(animationID)
        }
        .frame(height: 24)
        .padding(.horizontal, 12)
    }

    private var tickerRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Text(separator)
                        .foregroundStyle(.secondary)
                }
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
    }

    private func restartAnimation(viewWidth: CGFloat) {
        guard contentWidth > 0, viewWidth > 0, speed > 0 else { return }
        let distance = contentWidth + viewWidth
        let duration = Double(distance) / speed
        offset = viewWidth
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offset = -contentWidth
        }
    }
}

private struct TickerContentWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
