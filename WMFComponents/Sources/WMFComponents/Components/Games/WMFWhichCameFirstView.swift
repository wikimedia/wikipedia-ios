import SwiftUI
import UIKit

public struct WMFWhichCameFirstView: View {
    
    @ObservedObject var viewModel: WMFWhichCameFirstViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    private var theme: WMFTheme {
        appEnvironment.theme
    }
    
    public var body: some View {
        content
            .background(Color(uiColor: theme.paperBackground))
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .loading:
            loadingView
        case .presenting,
                .awaitingSubmission,
                .revealing,
                .transitioning:
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
            
            ScrollView {
                
                VStack(spacing: 18) {
                    
                    progressHeader
                    
                    if viewModel.showTitle {
                        
                        titleView
                            .transition(
                                .move(edge: .top)
                                .combined(with: .opacity)
                            )
                    }
                    
                    if viewModel.showCardA,
                       let cardA = viewModel.cardViewModelA {
                        
                        WMFOnThisDayCardView(viewModel: cardA) {
                            viewModel.select("A")
                        }
                        .transition(
                            .move(edge: .bottom)
                            .combined(with: .opacity)
                        )
                    }
                    
                    if viewModel.showCardB,
                       let cardB = viewModel.cardViewModelB {
                        
                        WMFOnThisDayCardView(viewModel: cardB) {
                            viewModel.select("B")
                        }
                        .transition(
                            .move(edge: .bottom)
                            .combined(with: .opacity)
                        )
                    }
                }
                .padding()
            }
            
            footerArea
        }
    }
    
    // MARK: - Footer
    
    private var footerArea: some View {
        VStack(spacing: 14) {
            
            if let reveal = viewModel.revealState {
                
                feedbackBanner(reveal)
            }
            
            if viewModel.phase == .awaitingSubmission {
                
                Button("Submit") {
                    viewModel.submitSelectedAnswer()
                }
                // .buttonStyle(GameButtonStyle(theme: theme))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if viewModel.phase == .revealing {
                
                Button(
                    viewModel.currentIndex == viewModel.totalQuestions - 1
                    ? "See Results"
                    : "Next"
                ) {
                    viewModel.animateOutAndAdvance()
                }
                // .buttonStyle(GameButtonStyle(theme: theme))
            }
            
            progressTracker
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
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
    
    private var progressHeader: some View {
        HStack {
            Text(
                "Question \(viewModel.currentIndex + 1) of \(viewModel.totalQuestions)"
            )
            .font(Font(WMFFont.for(.caption1)))
            .foregroundColor(Color(uiColor: theme.secondaryText))
            
            Spacer()
            
            Text("Score: \(viewModel.score)")
                .font(Font(WMFFont.for(.caption1)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
        }
    }
    
    private var progressTracker: some View {
        HStack(spacing: 8) {
            ForEach(
                Array(viewModel.progressResults.enumerated()),
                id: \.offset
            ) { index, result in
                
                Circle()
                    .fill(color(for: result))
                    .frame(width: 10, height: 10)
                    .scaleEffect(
                        index == viewModel.currentIndex
                        ? 1.3
                        : 1.0
                    )
                    .animation(
                        .spring(duration: 0.25),
                        value: result
                    )
            }
        }
    }
    
    private func feedbackBanner(
        _ reveal: WMFWhichCameFirstViewModel.RevealState
    ) -> some View {
        
        HStack(spacing: 10) {
            
            Image(
                systemName: reveal.isCorrect
                ? "checkmark.circle.fill"
                : "xmark.circle.fill"
            )
            
            Text(reveal.isCorrect ? "Correct!" : "Incorrect")
                .font(Font(WMFFont.for(.semiboldSubheadline)))
        }
        .foregroundColor(reveal.isCorrect ? .green : .orange)
    }
    
    private func color(for result: Bool?) -> Color {
        switch result {
            
        case true:
            return .green
            
        case false:
            return .orange
            
        case nil:
            return .gray.opacity(0.25)
        }
    }
    
    // MARK: - Complete
    
    private var completeView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Game Complete!")
                .font(Font(WMFFont.for(.semiboldHeadline)))
            Text("\(viewModel.score) / \(viewModel.totalQuestions)")
                .font(Font(WMFFont.for(.boldTitle1)))
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Error
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text("Something went wrong")
            Text(message)
            Button("Retry") {
                viewModel.load()
            }
            // .buttonStyle(GameButtonStyle(theme: theme))
        }
        .padding()
    }
}
