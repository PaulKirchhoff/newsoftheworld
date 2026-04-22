import AppKit
import SwiftUI

struct TickerView: View {
    let items: [NewsItem]
    let speed: Double
    let separator: String
    let fontSize: CGFloat

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
                    .frame(width: currentViewWidth, height: geo.size.height, alignment: .leading)
                    .clipped()
            }
            .onChange(of: geo.size.width, initial: true) { _, newValue in
                if anchorDate == .distantPast, newValue > 0 {
                    anchorDate = Date()
                    anchorOffset = newValue
                    viewWidth = newValue
                } else if newValue != viewWidth {
                    rebaseForSizeChange(oldViewWidth: viewWidth, oldContentWidth: contentWidth)
                    viewWidth = newValue
                }
            }
        }
        .padding(.horizontal, 12)
        .onPreferenceChange(TickerContentWidthKey.self) { newWidth in
            guard newWidth != contentWidth else { return }
            rebaseForSizeChange(oldViewWidth: viewWidth, oldContentWidth: contentWidth)
            contentWidth = newWidth
        }
        .onChange(of: speed) { oldSpeed, _ in
            rebaseForSpeedChange(oldSpeed: oldSpeed)
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
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                headline(for: item)
                    .lineLimit(1)
                    .contentShape(Rectangle())
                    .onTapGesture { openURL(for: item) }
                    .onHover { hovering in
                        if item.url != nil {
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
            }
        }
    }

    private func openURL(for item: NewsItem) {
        guard let url = item.url else { return }
        NSWorkspace.shared.open(url)
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
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(.primary)

        guard let category = item.category, !category.isEmpty else {
            return title
        }
        let prefix = Text("\(category): ")
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(.accentColor)
        return Text("\(prefix)\(title)")
    }

    private func rebaseForSpeedChange(oldSpeed: Double) {
        guard anchorDate != .distantPast else { return }
        let elapsed = CGFloat(Date().timeIntervalSince(anchorDate))
        anchorOffset -= elapsed * CGFloat(oldSpeed)
        anchorDate = Date()
    }

    private func rebaseForSizeChange(oldViewWidth: CGFloat, oldContentWidth: CGFloat) {
        guard anchorDate != .distantPast else { return }
        let oldCycleLength = oldContentWidth + oldViewWidth
        guard oldCycleLength > 0 else { return }
        let now = Date()
        let elapsed = CGFloat(now.timeIntervalSince(anchorDate))
        let oldVirtual = anchorOffset - elapsed * CGFloat(speed)
        let cyclesCompleted = floor((oldViewWidth - oldVirtual) / oldCycleLength)
        let visible = oldVirtual + cyclesCompleted * oldCycleLength
        anchorOffset = visible
        anchorDate = now
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
