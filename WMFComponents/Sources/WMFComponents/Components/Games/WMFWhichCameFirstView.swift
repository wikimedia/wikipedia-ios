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
            completeView
        case .error(let message):
            errorView(message)
        }
    }

    // MARK: - Gameplay

    private var gameplayView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {

                ZStack {
                    Color(uiColor: theme.link)

                    if viewModel.showTitle {
                        Text(viewModel.localizedStrings.title)
                            .minimumScaleFactor(0.3)
                            .font(Font(WMFFont.for(.semiboldTitle3)))
                            .foregroundColor(Color(uiColor: theme.baseBackground))
                            .multilineTextAlignment(.center)
                            .layoutPriority(1)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                            .opacity(viewModel.cardViewModelA?.isRevealed == true ? 0 : 1)
                    }
                }
                .frame(height: geometry.size.height / 4)

                VStack(spacing: 0) {

                    if viewModel.showCardA, let cardA = viewModel.cardViewModelA {
                        WMFOnThisDayCardView(viewModel: cardA) {
                            viewModel.select("A")
                        }
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }

                    if let reveal = viewModel.revealState {
                        feedbackBanner(reveal)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 49)
                    } else {
                        Spacer().frame(height: 32)
                    }

                    if viewModel.showCardB, let cardB = viewModel.cardViewModelB {
                        WMFOnThisDayCardView(viewModel: cardB) {
                            viewModel.select("B")
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

            HStack(spacing: 8) {
                ForEach(Array(viewModel.progressResults.enumerated()), id: \.offset) { index, result in

                    ZStack {
                        if let result = result {

                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .minimumScaleFactor(0.3)
                                .font(.title3)
                                .foregroundStyle(
                                    result
                                    ? Color(uiColor: theme.accent)
                                    : Color(uiColor: theme.destructive)
                                )

                        } else {

                            Circle()
                                .fill(color(for: nil))
                                .frame(width: 20, height: 20)
                                .scaleEffect(index == viewModel.currentIndex ? 1.3 : 1.0)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: 20, height: 20)
                    .animation(.spring(duration: 0.3), value: result)
                    .accessibilityHidden(true)
                }
            }
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
                            .minimumScaleFactor(0.1)
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
                        .minimumScaleFactor(0.1)
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
                reveal.isCorrect
                ? viewModel.localizedStrings.correctFeedback
                : viewModel.localizedStrings.incorrectFeedback
            )
            .minimumScaleFactor(0.3)
            .font(Font(WMFFont.for(.footnote)))
            .foregroundColor(Color(uiColor: theme.text))
            .lineLimit(2)

            if reveal.isCorrect {

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
    }

    private func color(for result: Bool?) -> Color {
        switch result {
        case true:
            return Color(uiColor: theme.accent)

        case false:
            return Color(uiColor: theme.destructive)

        case nil:
            return Color(uiColor: theme.newBorder)
        }
    }

    // MARK: - Complete

    private var completeView: some View {

        VStack(spacing: 24) {

            Spacer()

            Text(viewModel.localizedStrings.gameCompleteTitle)
                .minimumScaleFactor(0.3)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(uiColor: theme.text))

            Text("\(viewModel.score) / \(viewModel.totalQuestions)")
                .minimumScaleFactor(0.3)
                .font(Font(WMFFont.for(.boldTitle1)))
                .foregroundColor(Color(uiColor: theme.text))

            Text(scoreMessage)
                .minimumScaleFactor(0.3)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    private var scoreMessage: String {
        switch viewModel.score {

        case viewModel.totalQuestions:
            return viewModel.localizedStrings.perfectScoreMessage

        case (viewModel.totalQuestions / 2)...:
            return viewModel.localizedStrings.niceWorkMessage

        default:
            return viewModel.localizedStrings.betterLuckMessage
        }
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

            Button(viewModel.localizedStrings.retryButton) {
                viewModel.load()
            }
            .buttonStyle(WMFGameButtonStyle(theme: theme))
            .minimumScaleFactor(0.3)
        }
        .padding()
    }
}

// MARK: - Button Style

struct WMFGameButtonStyle: ButtonStyle {

    let theme: WMFTheme

    func makeBody(configuration: Configuration) -> some View {

        configuration.label
            .font(Font(WMFFont.for(.semiboldSubheadline)))
            .foregroundColor(Color(uiColor: theme.paperBackground))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(uiColor: theme.link))
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

