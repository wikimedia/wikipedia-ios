import SwiftUI
import UIKit

// MARK: - Results View

public struct WMFWhichCameFirstResultsView: View {
    
    @ObservedObject var viewModel: WMFWhichCameFirstResultsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    public init(viewModel: WMFWhichCameFirstResultsViewModel) {
        self.viewModel = viewModel
    }
    
    private var theme: WMFTheme { appEnvironment.theme }
    
    private func headerHeight(for height: CGFloat) -> CGFloat {
        let isCompactPhone = UIDevice.current.userInterfaceIdiom != .pad && height <= 667
        return isCompactPhone ? height / 5 : height / 4
    }
    
    private var isAccessibilitySize: Bool {
        dynamicTypeSize.isAccessibilitySize
    }
    
    private func formattedAverageScore(_ score: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: score)) ?? "\(score)"
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            
            ZStack(alignment: .top) {
                Color(uiColor: theme.midBackground)
                    .ignoresSafeArea()
                
                Color(uiColor: theme.link)
                    .frame(height: headerHeight(for: height))
                    .zIndex(0)
                
                ScrollView {
                    VStack(spacing: 24) {
                        scoreCard
                            .padding(.horizontal, 16)

                        statsSection
                            .padding(.horizontal, 16)
                        WMFWhichCameFirstArticlesView(viewModel: viewModel.articlesViewModel)
                    }
                    .padding(.top, headerHeight(for: height) - 123)
                    .padding(.bottom, 24)
                }
                .zIndex(1)
            }
        }
    }
    
    // MARK: - Score Card
    
    private enum Score {
        case low
        case medium
        case high
        
        init(score: Int, total: Int) {
            switch score {
            case total:
                self = .high
            case ((total / 2) + 1)..<total:
                self = .medium
            default:
                self = .low
            }
        }
    }
    
    private var currentScore: Score {
        Score(score: viewModel.score, total: viewModel.totalQuestions)
    }
    
    private var scoreCardColor: Color {
        switch currentScore {
        case .high:   return Color(red: 0.18, green: 0.69, blue: 0.52)
        case .medium: return Color(red: 0.96, green: 0.60, blue: 0.07)
        case .low:    return Color(red: 0.98, green: 0.76, blue: 0.15)
        }
    }
    
    private var scoreCard: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(viewModel.localizedStrings.scoreLabel(viewModel.score, of: viewModel.totalQuestions))
                .font(Font(WMFFont.for(.georgiaTitle1)))
            // Specifically left as hardcoded color
                .foregroundStyle(Color.black)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 6) {
                if let image = WMFSFSymbolIcon.for(symbol: .clock, font: .body) {
                    Image(uiImage: image)
                    // Specifically left as hardcoded color
                        .foregroundStyle(Color.black)
                        .accessibilityHidden(true)
                }
                Text(viewModel.localizedStrings.countdownLabel(from: viewModel.nextGameCountdownString))
                    .font(Font(WMFFont.for(.callout)).monospacedDigit())
                // Specifically left as hardcoded color
                    .foregroundStyle(Color.black)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Button {
                viewModel.shareScore?()
            } label: {
                HStack(alignment: .center, spacing: 4) {
                    if let image = WMFSFSymbolIcon.for(symbol: .squareAndArrowUp, font: .semiboldSubheadline) {
                        Image(uiImage: image)
                            .accessibilityHidden(true)
                    }
                    Text(viewModel.localizedStrings.shareScoreButton)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                        .fixedSize(horizontal: false, vertical: true)
                }
                // Specifically left as hardcoded color
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                // Specifically left as hardcoded color
                .background(.black.opacity(0.3))
                .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(scoreCardColor)
            // Specifically left as hardcoded color
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
        )
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.localizedStrings.yourStatsTitle)
                .font(Font(WMFFont.for(.semiboldSubheadline)))
                .foregroundColor(Color(uiColor: theme.text))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            if viewModel.isLoggedIn {
                loggedInStats
            } else {
                loggedOutStats
            }
        }
        .background(Color(uiColor: theme.paperBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)
    }
    
    private var loggedInStats: some View {
        Group {
            if isAccessibilitySize {
                VStack(spacing: 0) {
                    statCell(
                        symbol: .gameControllerFill,
                        value: viewModel.gamesPlayed.map { "\($0)" } ?? "–",
                        label: viewModel.localizedStrings.gamesPlayedLabel
                    )
                    Divider()
                    statCell(
                        symbol: .starSquare,
                        value: viewModel.currentStreak.map { "\($0)" } ?? "–",
                        label: viewModel.localizedStrings.currentStreakLabel
                    )
                    Divider()
                    statCell(
                        symbol: .medalStar,
                        value: viewModel.bestStreak.map { "\($0)" } ?? "–",
                        label: viewModel.localizedStrings.bestStreakLabel
                    )
                    Divider()
                    statCell(
                        symbol: .flagPatternCheckered,
                        value: viewModel.averageScore.map { formattedAverageScore($0) } ?? "–",
                        label: viewModel.localizedStrings.averageScoreLabel
                    )
                }
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        statCell(
                            symbol: .gameControllerFill,
                            value: viewModel.gamesPlayed.map { "\($0)" } ?? "–",
                            label: viewModel.localizedStrings.gamesPlayedLabel
                        )
                        statCell(
                            symbol: .starSquare,
                            value: viewModel.currentStreak.map { "\($0)" } ?? "–",
                            label: viewModel.localizedStrings.currentStreakLabel
                        )
                    }
                    HStack(spacing: 0) {
                        statCell(
                            symbol: .medalStar,
                            value: viewModel.bestStreak.map { "\($0)" } ?? "–",
                            label: viewModel.localizedStrings.bestStreakLabel
                        )
                        statCell(
                            symbol: .flagPatternCheckered,
                            value: viewModel.averageScore.map { "\($0)" } ?? "–",
                            label: viewModel.localizedStrings.averageScoreLabel
                        )
                    }
                }
            }
        }
    }

    private func statCell(symbol: WMFSFSymbolIcon, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            if let image = WMFSFSymbolIcon.for(symbol: symbol, font: .title3) {
                Image(uiImage: image)
                    .foregroundColor(Color(uiColor: theme.link))
                    .frame(width: 32, alignment: .center)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Font(WMFFont.for(.boldCallout)))
                    .foregroundColor(Color(uiColor: theme.text))
                    .minimumScaleFactor(0.8)
                Text(label)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundColor(Color(uiColor: theme.text))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var loggedOutStats: some View {
        VStack(spacing: 8) {
            Text(viewModel.localizedStrings.logInToViewStatsTitle)
                .font(Font(WMFFont.for(.semiboldSubheadline)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(viewModel.localizedStrings.logInToViewStatsBody)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Button {
                viewModel.onLogIn?()
            } label: {
                HStack(spacing: 4) {
                    if let image = WMFSFSymbolIcon.for(symbol: .personFilled, font: .semiboldSubheadline) {
                        Image(uiImage: image)
                            .accessibilityHidden(true)
                    }
                    Text(viewModel.localizedStrings.logInButton)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(Color(uiColor: theme.paperBackground))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color(uiColor: theme.link))
                .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }
}
