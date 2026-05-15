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
        VStack(spacing: 0) {
            ZStack {
                Color(uiColor: theme.link)
                Text("Which came first?")
                    .font(Font(WMFFont.for(.semiboldTitle3)))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
            }
            .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 18) {
                if viewModel.showCardA, let cardA = viewModel.cardViewModelA {
                    WMFOnThisDayCardView(viewModel: cardA) {
                        viewModel.select("A")
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if viewModel.showCardB, let cardB = viewModel.cardViewModelB {
                    WMFOnThisDayCardView(viewModel: cardB) {
                        viewModel.select("B")
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                Spacer()
                
                footerArea
            }
            .padding(.horizontal, 16)
            .padding(.top, -16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(uiColor: theme.midBackground))
        }
        .background(Color(uiColor: theme.link)) // fills the gap behind the nav bar
    }

    // MARK: - Footer

    private var footerArea: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.progressResults.enumerated()), id: \.offset) { index, result in
                    Circle()
                        .fill(color(for: result))
                        .frame(width: 10, height: 10)
                        .scaleEffect(index == viewModel.currentIndex ? 1.3 : 1.0)
                        .animation(.spring(duration: 0.25), value: result)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())

            Spacer()

            // Action button pill
            if viewModel.phase == .awaitingSubmission {
                Button("Submit") { viewModel.submitSelectedAnswer() }
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundColor(Color(uiColor: theme.text))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if viewModel.phase == .revealing {
                Button {
                    viewModel.animateOutAndAdvance()
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.currentIndex == viewModel.totalQuestions - 1 ? "See Results" : "Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundColor(Color(uiColor: theme.text))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: Capsule())
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

    private var titleView: some View {
        Text("Which came first?")
            .font(Font(WMFFont.for(.semiboldHeadline)))
            .foregroundColor(Color(uiColor: theme.text))
            .multilineTextAlignment(.center)
    }

    private var progressTracker: some View {
        HStack(spacing: 8) {
            ForEach(Array(viewModel.progressResults.enumerated()), id: \.offset) { index, result in
                Circle()
                    .fill(color(for: result))
                    .frame(width: 10, height: 10)
                    .scaleEffect(index == viewModel.currentIndex ? 1.3 : 1.0)
                    .animation(.spring(duration: 0.25), value: result)
            }
        }
    }

    private func feedbackBanner(_ reveal: WMFWhichCameFirstViewModel.RevealState) -> some View {
        HStack(spacing: 10) {
            Image(systemName: reveal.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(reveal.isCorrect ? "Correct!" : "Incorrect")
                .font(Font(WMFFont.for(.semiboldSubheadline)))
        }
        .foregroundColor(reveal.isCorrect ? Color(uiColor: theme.accent) : Color(uiColor: theme.destructive))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(reveal.isCorrect
                      ? Color(uiColor: theme.accent).opacity(0.12)
                      : Color(uiColor: theme.destructive).opacity(0.12))
        )
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
            Text("Game Complete!")
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
        case viewModel.totalQuestions:       return "Perfect score!"
        case (viewModel.totalQuestions / 2)...: return "Nice work! Come back tomorrow for a new game."
        default:                             return "Better luck tomorrow!"
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text("Something went wrong")
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(uiColor: theme.text))
            Text(message)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)
            Button("Retry") { viewModel.load() }
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
    let vm = WMFWhichCameFirstViewModel(date: "2026-01-06", project: .wikipedia(.init(languageCode: "en", languageVariantCode: nil)))

    // Manually push into presenting state with mock cards
    vm.cardViewModelA = WMFOnThisDayCardViewModel(
        event: WMFOnThisDayCardEvent(
            text: "The Apollo 11 mission successfully lands the first humans on the Moon.",
            date: Date(),
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/3/3d/Apollo_11_Crew.jpg?utm_source=commons.wikimedia.org&utm_campaign=index&utm_content=original")
        )
    )
    vm.cardViewModelB = WMFOnThisDayCardViewModel(
        event: WMFOnThisDayCardEvent(
            text: "The World Wide Web is invented by Tim Berners-Lee at CERN.",
            date: Date()
        )
    )
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
