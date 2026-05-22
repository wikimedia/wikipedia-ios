import SwiftUI
import UIKit

// MARK: - Results View

public struct WMFWhichCameFirstResultsView: View {

    @ObservedObject var viewModel: WMFWhichCameFirstResultsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme { appEnvironment.theme }


    private func headerHeight(for height: CGFloat) -> CGFloat {
        let isCompactPhone = UIDevice.current.userInterfaceIdiom != .pad && height <= 667
        return isCompactPhone ? height / 5 : height / 4
    }

    private func isSmallScreen(_ height: CGFloat) -> Bool { height < 700 }
    private func cardHeight(_ height: CGFloat) -> CGFloat { isSmallScreen(height) ? 150 : 167 }

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

                        playArchiveButton
                            .padding(.horizontal, 16)

                        statsSection
                            .padding(.horizontal, 16)

                        if !viewModel.referencedArticles.isEmpty {
                            articlesSection
                                .padding(.bottom, 24)
                        }
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
            Text(viewModel.localizedStrings.scoredLabel(viewModel.score, of: viewModel.totalQuestions))
                .font(Font(WMFFont.for(.georgiaTitle1)))
            // Specificlly left as hardcoded color
                .foregroundStyle(Color.black)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(Font(WMFFont.for(.body)))
                // Specificlly left as hardcoded color
                    .foregroundStyle(Color.black)
                Text(viewModel.localizedStrings.countdownLabel(from: viewModel.nextGameCountdownString))
                    .font(Font(WMFFont.for(.callout)))
                // Specificlly left as hardcoded color
                    .foregroundStyle(Color.black)
            }

            Button {
                viewModel.shareScore()
            } label: {
                HStack(alignment: .center, spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                    Text(viewModel.localizedStrings.shareScoreButton)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                }
                // Specificlly left as hardcoded color
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                // Specificlly left as hardcoded color
                .background(.black.opacity(0.3))
                .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 167)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(scoreCardColor)
            // Specificlly left as hardcoded color
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
        )
    }

    // MARK: - Play Archive Button

    private var playArchiveButton: some View {
        Button {
            viewModel.playArchive()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(Font(WMFFont.for(.semiboldHeadline)))
                Text(viewModel.localizedStrings.playArchiveButton)
                    .font(Font(WMFFont.for(.semiboldHeadline)))
            }
            .foregroundColor(Color(uiColor: theme.link))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color(uiColor: theme.baseBackground))
            )
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.localizedStrings.yourStatsTitle)
                .font(Font(WMFFont.for(.semiboldSubheadline)))
                .foregroundColor(Color(uiColor: theme.text))

            if viewModel.isLoggedIn {
                loggedInStats
            } else {
                loggedOutStats
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)
    }

    private var loggedInStats: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                statCell(
                    icon: "gamecontroller.fill",
                    value: viewModel.gamesPlayed.map { "\($0)" } ?? "–",
                    label: viewModel.localizedStrings.gamesPlayedLabel
                )
                statCell(
                    icon: "star.square.on.square",
                    value: viewModel.currentStreak.map { "\($0)" } ?? "–",
                    label: viewModel.localizedStrings.currentStreakLabel
                )
            }
            HStack(spacing: 0) {
                statCell(
                    icon: "medal.star",
                    value: viewModel.bestStreak.map { "\($0)" } ?? "–",
                    label: viewModel.localizedStrings.bestStreakLabel
                )
                statCell(
                    icon: "flag.pattern.checkered",
                    value: viewModel.averageScore.map { "\($0)" } ?? "–",
                    label: viewModel.localizedStrings.averageScoreLabel
                )
            }
        }
        .background(Color(uiColor: theme.paperBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCell(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(uiColor: theme.link))
                .frame(width: 32, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Font(WMFFont.for(.boldCallout)))
                    .foregroundColor(Color(uiColor: theme.text))
                Text(label)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundColor(Color(uiColor: theme.text))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var loggedOutStats: some View {
        VStack(spacing: 12) {
            Text(viewModel.localizedStrings.logInToViewStatsTitle)
                .font(Font(WMFFont.for(.semiboldSubheadline)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)

            Text(viewModel.localizedStrings.logInToViewStatsBody)
                .font(Font(WMFFont.for(.footnote)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)

            Button {
                viewModel.logIn()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person")
                    Text(viewModel.localizedStrings.logInButton)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                }
                .foregroundColor(Color(uiColor: theme.paperBackground))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(uiColor: theme.link))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(uiColor: theme.paperBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Articles Section

    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.localizedStrings.articlesReferencedTitle)
                .font(Font(WMFFont.for(.semiboldSubheadline)))
                .foregroundColor(Color(uiColor: theme.text))
                .padding(.horizontal, 16)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(viewModel.referencedArticles) { article in
                    articleCard(article)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func articleCard(_ article: WMFWhichCameFirstResultsArticle) -> some View {
        Button {
            viewModel.openArticle(article)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                if let imageURL = article.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color(uiColor: theme.newBorder)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .clipped()
                } else {
                    Color(uiColor: theme.newBorder)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                }

                /*
                 todo
                 if let data = viewModel.thumbnailImageData,
                    let uiImage = UIImage(data: data) {
                     Image(uiImage: uiImage)
                         .resizable()
                         .scaledToFill()
                         .frame(width: 100, height: 100)
                         .clipShape(
                             UnevenRoundedRectangle(
                                 topLeadingRadius: 0,
                                 bottomLeadingRadius: 0,
                                 bottomTrailingRadius: 0,
                                 topTrailingRadius: 8
                             )
                         )
                 } else {
                     UnevenRoundedRectangle(
                         topLeadingRadius: 0,
                         bottomLeadingRadius: 0,
                         bottomTrailingRadius: 0,
                         topTrailingRadius: 8
                     )
                     .fill(Color(uiColor: theme.midBackground))
                     .frame(width: 100, height: 100)
                     .overlay(ProgressView().scaleEffect(0.7))
                 }
                 */

                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                        .foregroundColor(Color(uiColor: theme.text))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let description = article.description {
                        Text(description)
                            .font(Font(WMFFont.for(.footnote)))
                            .foregroundColor(Color(uiColor: theme.secondaryText))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "ellipsis")
                        .font(.footnote)
                        .foregroundColor(Color(uiColor: theme.secondaryText))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(10)
            }
            .background(Color(uiColor: theme.paperBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Results Article Model

public struct WMFWhichCameFirstResultsArticle: Identifiable {
    public let id: UUID
    public let title: String
    public let description: String?
    public let imageURL: URL?

    public init(id: UUID = UUID(), title: String, description: String?, imageURL: URL?) {
        self.id = id
        self.title = title
        self.description = description
        self.imageURL = imageURL
    }
}

// MARK: - Previews

private let previewArticles: [WMFWhichCameFirstResultsArticle] = [
    .init(
        title: "Apollo 11",
        description: "First crewed Moon landing mission conducted by NASA.",
        imageURL: URL(string: "https://www.mediawiki.org/wiki/Help:Images#/media/File:Example.jpg/")
    ),
    .init(
        title: "The Internet",
        description: "Global system of interconnected computer networks.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/6/6a/Internet_map_1024.jpg")
    ),
    .init(
        title: "Mount Everest",
        description: "Earth's highest mountain above sea level.",
        imageURL: nil
    ),
    .init(
        title: "Printing Press",
        description: "Mechanical device for mass-producing printed text.",
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0c/Gutenberg.jpg")
    )
]

#Preview("Logged In 1") {
    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 1, totalQuestions: 5, isLoggedIn: true,
        gamesPlayed: 42, currentStreak: 6, bestStreak: 18, averageScore: 7,
        referencedArticles: previewArticles
    )
    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}

#Preview("Logged In 2") {
    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 2, totalQuestions: 5, isLoggedIn: true,
        gamesPlayed: 42, currentStreak: 6, bestStreak: 18, averageScore: 7,
        referencedArticles: previewArticles
    )
    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}

#Preview("Logged In 3") {
    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 3, totalQuestions: 5, isLoggedIn: true,
        gamesPlayed: 42, currentStreak: 6, bestStreak: 18, averageScore: 7,
        referencedArticles: previewArticles
    )
    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}

#Preview("Logged In 4") {
    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 4, totalQuestions: 5, isLoggedIn: true,
        gamesPlayed: 42, currentStreak: 6, bestStreak: 18, averageScore: 7,
        referencedArticles: previewArticles
    )
    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}

#Preview("Logged In 5") {
    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 5, totalQuestions: 5, isLoggedIn: true,
        gamesPlayed: 42, currentStreak: 6, bestStreak: 18, averageScore: 7,
        referencedArticles: previewArticles
    )
    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}

#Preview("Logged Out") {
    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 4, totalQuestions: 5, isLoggedIn: false,
        referencedArticles: []
    )
    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}
