import SwiftUI

/// The floating pill that names the last event the analytics pipeline received.
struct WMFAnalyticsInspectorPillView: View {

    @ObservedObject var viewModel: WMFAnalyticsInspectorViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    @State private var isHighlighted = false
    @State private var highlightTask: Task<Void, Never>?

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    private var isDropped: Bool {
        viewModel.latestEvent?.outcome.isDropped ?? false
    }

    private var backgroundColor: Color {
        isDropped ? Color(theme.destructive) : Color(theme.text)
    }

    var body: some View {
        HStack(spacing: WMFSpacing.xSmall) {
            Circle()
                .fill(Color(theme.paperBackground))
                .frame(width: 6, height: 6)
            Text(viewModel.pillText(for: viewModel.latestEvent))
                .font(Font(WMFFont.for(.boldCaption1)))
                .lineLimit(1)
        }
        .foregroundStyle(Color(theme.paperBackground))
        .padding(.horizontal, WMFSpacing.medium)
        .padding(.vertical, WMFSpacing.small)
        .background(Capsule().fill(backgroundColor))
        .shadow(color: Color(theme.toastShadow).opacity(0.3), radius: 4, y: 2)
        .scaleEffect(isHighlighted ? 1.08 : 1)
        .frame(maxWidth: 280)
        .contentShape(Capsule())
        .onTapGesture {
            viewModel.didTapPill?()
        }
        .onChange(of: viewModel.latestEvent?.id) {
            flash()
        }
        .accessibilityIdentifier("analytics-inspector-pill")
    }

    private func flash() {
        highlightTask?.cancel()
        withAnimation(.easeOut(duration: 0.12)) {
            isHighlighted = true
        }
        highlightTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else {
                return
            }
            withAnimation(.easeIn(duration: 0.2)) {
                isHighlighted = false
            }
        }
    }
}
