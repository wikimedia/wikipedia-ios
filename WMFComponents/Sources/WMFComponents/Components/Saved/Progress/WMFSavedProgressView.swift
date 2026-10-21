import SwiftUI
import WMFNativeLocalizations

/// Pill that sits at the bottom of the Saved tab while saved articles download.
public struct WMFSavedProgressView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSavedProgressViewModel

    private let title = CommonStrings.savedArticleDownloadInProgress
    private let cornerRadius = WMFCornerRadius.xxLarge

    public init(viewModel: WMFSavedProgressViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            if viewModel.isVisible {
                pill
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isVisible)
    }

    private var pill: some View {
        VStack(alignment: .leading, spacing: WMFSpacing.small) {
            Text(title)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: appEnvironment.theme.text))
            ProgressView(value: viewModel.fractionCompleted)
                .progressViewStyle(.linear)
                .tint(Color(uiColor: appEnvironment.theme.accent))
        }
        .padding(.horizontal, WMFSpacing.large)
        .padding(.vertical, WMFSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(pillBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .circular))
        .padding(.horizontal, WMFSpacing.large)
        .padding(.bottom, WMFSpacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AccessibilityIdentifiers.Saved.progressView)
    }

    @ViewBuilder
    private var pillBackground: some View {
        let paper = Color(uiColor: appEnvironment.theme.paperBackground)
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular.tint(paper.opacity(0.85)), in: RoundedRectangle(cornerRadius: cornerRadius, style: .circular))
        } else {
            paper
        }
    }
}
