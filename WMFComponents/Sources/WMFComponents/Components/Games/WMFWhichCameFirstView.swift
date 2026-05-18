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
            let isLandscape = geometry.size.width > geometry.size.height
            VStack(spacing: 0) {
                ZStack {
                    Color(uiColor: theme.link)

                    if viewModel.showTitle {
                        Text(viewModel.localizedStrings.title)
                            .font(Font(WMFFont.for(.semiboldTitle3)))
                            .foregroundColor(Color(uiColor: theme.baseBackground))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                            .opacity(viewModel.cardViewModelA?.isRevealed == true ? 0 : 1)
                    }
                }
                .frame(height: isLandscape ? 72: geometry.size.height / 4)

                VStack(spacing: 0) {
                    if isLandscape {
                        HStack(alignment: .top, spacing: 16) {

                            if viewModel.showCardA, let cardA = viewModel.cardViewModelA {
                                WMFOnThisDayCardView(viewModel: cardA) {
                                    viewModel.select("A")
                                }
                                .frame(maxWidth: .infinity)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }

                            if viewModel.showCardB, let cardB = viewModel.cardViewModelB {
                                WMFOnThisDayCardView(viewModel: cardB) {
                                    viewModel.select("B")
                                }
                                .frame(maxWidth: .infinity)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        if let reveal = viewModel.revealState {
                            feedbackBanner(reveal)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 24)
                        }

                    } else {

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
                        }
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
                            if let uiImage = WMFSFSymbolIcon.for(symbol: result ? .checkmarkCircleFill : .closeCircleFill, font: .title3) {
                                Image(uiImage: uiImage)
                                    .foregroundColor(result ? Color(uiColor: theme.accent) : Color(uiColor: theme.destructive))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        } else {
                            Circle()
                                .fill(color(for: nil))
                                .frame(width: 10, height: 10)
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
                Button(viewModel.localizedStrings.submitButton) { viewModel.submitSelectedAnswer() }
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundColor(Color(uiColor: theme.text))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
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
                        Text(viewModel.currentIndex == viewModel.totalQuestions - 1
                             ? viewModel.localizedStrings.seeResultsButton
                             : viewModel.localizedStrings.nextButton)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.center)
                        if let chevron = WMFSFSymbolIcon.for(symbol: .chevronForward, font: .semiboldSubheadline) {
                            Image(uiImage: chevron)
                        }
                    }
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundColor(Color(uiColor: theme.text))
                }
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
            Text(reveal.isCorrect ? viewModel.localizedStrings.correctFeedback : viewModel.localizedStrings.incorrectFeedback)
                .font(Font(WMFFont.for(.footnote)))
                .foregroundColor(Color(uiColor: theme.text))
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            if reveal.isCorrect {
                Text(viewModel.localizedStrings.correctFeedback2)
                    .font(Font(WMFFont.for(.footnote)))
                    .foregroundColor(Color(uiColor: theme.accent))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func color(for result: Bool?) -> Color {
        switch result {
        case true:  return Color(uiColor: theme.accent)
        case false: return Color(uiColor: theme.destructive)
        case nil:   return Color(uiColor: theme.border)
        }
    }

    // MARK: - Complete

    private var completeView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(viewModel.localizedStrings.gameCompleteTitle)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(uiColor: theme.text))
            Text("\(viewModel.score) / \(viewModel.totalQuestions)")
                .font(Font(WMFFont.for(.boldTitle1)))
                .foregroundColor(Color(uiColor: theme.text))
            Text(scoreMessage)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private var scoreMessage: String {
        switch viewModel.score {
        case viewModel.totalQuestions:          return viewModel.localizedStrings.perfectScoreMessage
        case (viewModel.totalQuestions / 2)...: return viewModel.localizedStrings.niceWorkMessage
        default:                                return viewModel.localizedStrings.betterLuckMessage
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text(viewModel.localizedStrings.errorTitle)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(uiColor: theme.text))
            Text(message)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)
            Button(viewModel.localizedStrings.retryButton) { viewModel.load() }
                .buttonStyle(WMFGameButtonStyle(theme: theme))
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

#Preview {
    let vm = WMFWhichCameFirstViewModel(date: "2026-01-06", project: .wikipedia(.init(languageCode: "en", languageVariantCode: nil)), localizedStrings: WMFWhichCameFirstViewModel.LocalizedStrings(
        title: "Which came first?",
        submitButton: "Submit",
        nextButton: "Next",
        seeResultsButton: "See Results",
        correctFeedback: "Correct!",
        correctFeedback2: "+1 point",
        incorrectFeedback: "Incorrect",
        gameCompleteTitle: "Game Complete!",
        perfectScoreMessage: "Perfect score!",
        niceWorkMessage: "Nice work! Come back tomorrow for a new game.",
        betterLuckMessage: "Better luck tomorrow!",
        errorTitle: "Something went wrong",
        retryButton: "Retry"
    ))

    vm.cardViewModelA = WMFOnThisDayCardViewModel(
        event: WMFOnThisDayCardEvent(
            text: "The Apollo 11 mission successfully lands the first humans on the Moon.",
            date: Date(),
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/3/3d/Apollo_11_Crew.jpg")
        )
    )
    vm.cardViewModelB = WMFOnThisDayCardViewModel(
        event: WMFOnThisDayCardEvent(
            text: "The World Wide Web is invented by Tim Berners-Lee at CERN.",
            date: Date()
        )
    )
    vm.showTitle = true
    vm.showCardA = true
    vm.showCardB = true
    vm.phase = .presenting
    vm.progressResults = [nil, nil, nil, nil, nil]

    return NavigationView {
        WMFWhichCameFirstView(viewModel: vm)
            .navigationTitle("January 6")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { } label: { Image(systemName: "ellipsis") }
                }
            }
            .toolbarBackground(Color(uiColor: WMFAppEnvironment.current.theme.link), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
