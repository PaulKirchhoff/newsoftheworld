import SwiftUI

struct TickerView: View {
    let items: [NewsItem]
    let speed: Double
    let separator: String

    @State private var contentWidth: CGFloat = 0
    @State private var viewWidth: CGFloat = 0
    @State private var anchorDate: Date = .distantPast
    @State private var anchorOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                let currentViewWidth = geo.size.width
                let offset = visualOffset(now: context.date, viewWidth: currentViewWidth)

                tickerRow
                    .fixedSize(horizontal: true, vertical: false)
                    .background(widthReader)
                    .offset(x: offset)
                    .frame(width: currentViewWidth, alignment: .leading)
                    .clipped()
            }
            .onChange(of: geo.size.width, initial: true) { _, newValue in
                viewWidth = newValue
                if anchorDate == .distantPast, newValue > 0 {
                    anchorDate = Date()
                    anchorOffset = newValue
                }
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 12)
        .onPreferenceChange(TickerContentWidthKey.self) { newWidth in
            if newWidth != contentWidth {
                contentWidth = newWidth
            }
        }
        .onChange(of: speed) { oldSpeed, _ in
            rebase(usingSpeed: oldSpeed)
        }
        .onChange(of: items) { _, _ in
            anchorDate = Date()
            anchorOffset = viewWidth
        }
    }

    private var tickerRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Text(separator)
                        .foregroundStyle(.secondary)
                }
                headline(for: item)
                    .lineLimit(1)
            }
        }
    }

    private var widthReader: some View {
        GeometryReader { contentGeo in
            Color.clear.preference(
                key: TickerContentWidthKey.self,
                value: contentGeo.size.width
            )
        }
    }

    private func headline(for item: NewsItem) -> Text {
        let title = Text(item.title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.primary)

        guard let category = item.category, !category.isEmpty else {
            return title
        }
        let prefix = Text("\(category): ")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.accentColor)
        return Text("\(prefix)\(title)")
    }

    private func rebase(usingSpeed oldSpeed: Double) {
        guard anchorDate != .distantPast else { return }
        let elapsed = CGFloat(Date().timeIntervalSince(anchorDate))
        anchorOffset -= elapsed * CGFloat(oldSpeed)
        anchorDate = Date()
    }

    private func visualOffset(now: Date, viewWidth: CGFloat) -> CGFloat {
        guard contentWidth > 0, viewWidth > 0, speed > 0, anchorDate != .distantPast else {
            return anchorOffset
        }
        let cycleLength = contentWidth + viewWidth
        let elapsed = CGFloat(now.timeIntervalSince(anchorDate))
        let virtual = anchorOffset - elapsed * CGFloat(speed)
        let cyclesCompleted = floor((viewWidth - virtual) / cycleLength)
        return virtual + cyclesCompleted * cycleLength
    }
}

private struct TickerContentWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
