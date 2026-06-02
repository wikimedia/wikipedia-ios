import SwiftUI
import UIKit

public struct WMFWhichCameFirstView: View {

    @ObservedObject var viewModel: WMFWhichCameFirstViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme { appEnvironment.theme }

    public var body: some View {
        content
            .background(Color(uiColor: theme.midBackground))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .loading:
            loadingView
        case .presenting, .awaitingSubmission, .revealing, .transitioning:
            gameplayView
        case .complete:
            CompleteView(gameViewModel: viewModel)
        case .error(let message):
            errorView(message)
        }
    }
    
    private struct CompleteView: View {
        let gameViewModel: WMFWhichCameFirstViewModel

        @StateObject private var resultsViewModel: WMFWhichCameFirstResultsViewModel

        init(gameViewModel: WMFWhichCameFirstViewModel) {
            self.gameViewModel = gameViewModel
            self._resultsViewModel = StateObject(wrappedValue: WMFWhichCameFirstResultsViewModel(
                score: gameViewModel.score,
                totalQuestions: gameViewModel.totalQuestions,
                isLoggedIn: gameViewModel.isLoggedIn,
                project: gameViewModel.project,
                questions: gameViewModel.questions,
                shareScore: gameViewModel.didTapShare,
                onLogIn: gameViewModel.onLogIn,
                onArticleTap: gameViewModel.onArticleTap,
                onArticleOpenInNewTab: gameViewModel.onArticleOpenInNewTab,
                onArticleOpenInBackgroundTab: gameViewModel.onArticleOpenInBackgroundTab,
                onArticleSaveForLater: gameViewModel.onArticleSaveForLater,
                onArticleUnsave: gameViewModel.onArticleUnsave,
                onCheckSavedState: gameViewModel.onCheckSavedState,
                onArticleShare: gameViewModel.onArticleShare,
                onArticleTapToEvent: gameViewModel.onArticleTapToEvent
            ))
        }

        var body: some View {
            if gameViewModel.totalQuestions > 0 {
                WMFWhichCameFirstResultsView(viewModel: resultsViewModel)
                    .onReceive(gameViewModel.$isLoggedIn) { isLoggedIn in
                        resultsViewModel.isLoggedIn = isLoggedIn
                    }
            }
        }
    }

    // MARK: - Gameplay

    private func headerHeight(for height: CGFloat) -> CGFloat {
        let isCompactPhone = UIDevice.current.userInterfaceIdiom != .pad && height <= 667
        return isCompactPhone ? height / 5 : height / 4
    }

    private func isSmallScreen(_ height: CGFloat) -> Bool { height < 700 }
    private func feedbackBannerPadding(_ height: CGFloat) -> CGFloat { isSmallScreen(height) ? 32 : 49 }
    private func cardHeight(_ height: CGFloat) -> CGFloat { isSmallScreen(height) ? 170 : 192 }

    private var gameplayView: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            VStack(spacing: 0) {

                ZStack(alignment: .bottom) {
                    Color(uiColor: theme.link)

                    if viewModel.showTitle {
                        Text(viewModel.localizedStrings.title)
                            .minimumScaleFactor(0.3)
                            .font(Font(WMFFont.for(.georgiaTitle1)))
                            .foregroundColor(Color(uiColor: theme.baseBackground))
                            .multilineTextAlignment(.center)
                            .layoutPriority(1)
                            .padding(.bottom, 40)
                            .padding(.vertical, 16)
                            .transition(.opacity)
                            .opacity(viewModel.cardViewModelA?.isRevealed == true ? 0 : 1)
                    }
                }
                .frame(height: headerHeight(for: height))

                VStack(spacing: 0) {
                    
                    if viewModel.showCardA, let cardA = viewModel.cardViewModelA {
                        WMFWhichCameFirstCardView(viewModel: cardA, parentViewModel: viewModel, cardHeight: cardHeight(height)) {
                            viewModel.select(.a)
                        }
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    
                    if let reveal = viewModel.revealState {
                        feedbackBanner(reveal)
                            .padding(.horizontal, 16)
                            .padding(.vertical, feedbackBannerPadding(height))
                    } else {
                        Spacer().frame(height: 32)
                    }
                    
                    if viewModel.showCardB, let cardB = viewModel.cardViewModelB {
                        WMFWhichCameFirstCardView(viewModel: cardB, parentViewModel: viewModel, cardHeight: cardHeight(height)) {
                            viewModel.select(.b)
                        }
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    footerArea
                }
                .padding(.top, viewModel.cardViewModelA?.isRevealed == true ? -96 : -16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color(uiColor: theme.midBackground))
            }
            .background(Color(uiColor: theme.link))
        }
    }

    // MARK: - Footer

    private var footerArea: some View {
        HStack(alignment: .center, spacing: 12) {
            ProgressDotsView(
                progressResults: viewModel.progressResults,
                theme: theme
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .accessibilityElement(children: .ignore)
            
            Spacer()

            if viewModel.phase == .awaitingSubmission {

                Button {
                    viewModel.submitSelectedAnswer()
                } label: {

                    HStack(spacing: 4) {

                        Text(viewModel.localizedStrings.submitButton)
                            .minimumScaleFactor(0.2)
                            .font(Font(WMFFont.for(.semiboldSubheadline)))
                            .multilineTextAlignment(.center)

                        if let image = WMFSFSymbolIcon.for(
                            symbol: .chevronForward,
                            font: .semiboldSubheadline,
                            compatibleWith: .wmfCappedForSFSymbols
                        ) {
                            Image(uiImage: image)
                        }
                    }
                    .layoutPriority(1)
                }
                .foregroundColor(Color(uiColor: theme.text))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: Capsule())
                .transition(.opacity)
            }

            if viewModel.phase == .revealing {

                Button {
                    viewModel.animateOutAndAdvance()

                } label: {

                    HStack(spacing: 4) {

                        Text(
                            viewModel.currentIndex == viewModel.totalQuestions - 1
                            ? viewModel.localizedStrings.seeResultsButton
                            : viewModel.localizedStrings.nextButton
                        )
                        .minimumScaleFactor(0.2)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                        .multilineTextAlignment(.center)

                        if let image = WMFSFSymbolIcon.for(
                            symbol: .chevronForward,
                            font: .semiboldSubheadline,
                            compatibleWith: .wmfCappedForSFSymbols
                        ) {
                            Image(uiImage: image)
                        }
                    }
                    .layoutPriority(1)
                }
                .foregroundColor(Color(uiColor: theme.text))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: Capsule())
                .transition(.opacity)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.localizedStrings.footera11y())
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .animation(.spring(duration: 0.3), value: viewModel.phase)
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func feedbackBanner(_ reveal: WMFWhichCameFirstViewModel.RevealState) -> some View {
        HStack(spacing: 4) {
            Text(
                reveal.correct == reveal.picked
                ? viewModel.localizedStrings.correctFeedback
                : viewModel.localizedStrings.incorrectFeedback
            )
            .minimumScaleFactor(0.3)
            .font(Font(WMFFont.for(.footnote)))
            .foregroundColor(Color(uiColor: theme.text))
            .lineLimit(2)

            if reveal.correct == reveal.picked {
                Text(viewModel.localizedStrings.correctFeedback2)
                    .minimumScaleFactor(0.3)
                    .font(Font(WMFFont.for(.footnote)))
                    .foregroundColor(Color(uiColor: theme.accent))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {

        VStack(spacing: 16) {

            Text(viewModel.localizedStrings.errorTitle)
                .minimumScaleFactor(0.3)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(uiColor: theme.text))

            Text(message)
                .minimumScaleFactor(0.3)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)

            WMFLargeButton(style: .primary, title: viewModel.localizedStrings.retryButton) {
                viewModel.load()
            }
            .padding(.horizontal, 16)
        }
        .padding()
    }
}

// MARK: - Progress Dots

private struct ProgressDotsView: View {

    let progressResults: [Bool?]
    let theme: WMFTheme

    @ScaledMetric(relativeTo: .title3) private var scaledDotSize: CGFloat = 20
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var dotSize: CGFloat {
        dynamicTypeSize <= .xLarge ? scaledDotSize : scaledDotSize(for: .xLarge)
    }

    private func scaledDotSize(for size: DynamicTypeSize) -> CGFloat {
        let xLargeMultiplier: CGFloat = 1.235
        return 20 * xLargeMultiplier
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(progressResults.enumerated()), id: \.offset) { index, result in
                ZStack {
                    if let result = result {
                        Image(uiImage: WMFSFSymbolIcon.for(symbol: result ? .checkmarkCircleFill : .closeCircleFill, font: .subheadline) ?? UIImage())
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: dotSize, height: dotSize)
                            .foregroundStyle(
                                result
                                ? Color(uiColor: WMFColor.green700)
                                : Color(uiColor: WMFColor.red700)
                            )
                    } else {
                        Circle()
                            .fill(color(for: nil))
                            .frame(width: dotSize, height: dotSize)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: dotSize, height: dotSize)
                .animation(.spring(duration: 0.3), value: result)
                .accessibilityHidden(true)
            }
        }
    }

    private func color(for result: Bool?) -> Color {
        switch result {
        case true:  return Color(uiColor: WMFColor.green700)
        case false: return Color(uiColor: WMFColor.red700)
        case nil:   return Color(uiColor: theme.newBorder)
        }
    }
}


