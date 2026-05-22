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
                    VStack(spacing: 0) {
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
        VStack(spacing: 8) {
            if currentScore == .medium || currentScore == .high {
                Text(viewModel.localizedStrings.scoredLabel(viewModel.score, of: viewModel.totalQuestions))
                    .font(Font(WMFFont.for(.boldTitle1)))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.85))
                Text(viewModel.localizedStrings.nextGameCountdown)
                    .font(Font(WMFFont.for(.footnote)))
                    .foregroundColor(.white.opacity(0.85))
            }

            Button {
                viewModel.shareScore()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                    Text(viewModel.localizedStrings.shareScoreButton)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.2))
                .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 167)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(scoreCardColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(
            color: Color(uiColor: theme.text).opacity(0.05),
            radius: 8,
            x: 0,
            y: 0
        )
        .contentShape(Rectangle())
    }

    // MARK: - Play Archive Button

    private var playArchiveButton: some View {
        Button {
            viewModel.playArchive()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "archivebox")
                    .font(Font(WMFFont.for(.subheadline)))
                Text(viewModel.localizedStrings.playArchiveButton)
                    .font(Font(WMFFont.for(.subheadline)))
            }
            .foregroundColor(Color(uiColor: theme.text))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
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
    }

    private var loggedInStats: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                statCell(
                    icon: "gamecontroller",
                    value: viewModel.gamesPlayed.map { "\($0)" } ?? "–",
                    label: viewModel.localizedStrings.gamesPlayedLabel
                )
                Divider().frame(height: 44)
                statCell(
                    icon: "arrow.triangle.2.circlepath",
                    value: viewModel.currentStreak.map { "\($0)" } ?? "–",
                    label: viewModel.localizedStrings.currentStreakLabel
                )
            }
            Divider()
            HStack(spacing: 0) {
                statCell(
                    icon: "medal",
                    value: viewModel.bestStreak.map { "\($0)" } ?? "–",
                    label: viewModel.localizedStrings.bestStreakLabel
                )
                Divider().frame(height: 44)
                statCell(
                    icon: "chart.bar",
                    value: viewModel.averageScore.map { "\($0)" } ?? "–",
                    label: viewModel.localizedStrings.averageScoreLabel
                )
            }
        }
        .background(Color(uiColor: theme.paperBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statCell(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundColor(Color(uiColor: theme.text))
                Text(label)
                    .font(Font(WMFFont.for(.footnote)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
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


#Preview("Logged In 1") {

    let articles: [WMFWhichCameFirstResultsArticle] = [
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
            description: "Earth’s highest mountain above sea level.",
            imageURL: nil
        ),
        .init(
            title: "Printing Press",
            description: "Mechanical device for mass-producing printed text.",
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0c/Gutenberg.jpg")
        )
    ]

    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 1,
        totalQuestions: 5,
        isLoggedIn: true,
        gamesPlayed: 42,
        currentStreak: 6,
        bestStreak: 18,
        averageScore: 7,
        referencedArticles: articles,
        nextGameCountdownString: "08:24:15"
    )

    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}

#Preview("Logged In 2") {

    let articles: [WMFWhichCameFirstResultsArticle] = [
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
            description: "Earth’s highest mountain above sea level.",
            imageURL: nil
        ),
        .init(
            title: "Printing Press",
            description: "Mechanical device for mass-producing printed text.",
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0c/Gutenberg.jpg")
        )
    ]

    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 2,
        totalQuestions: 5,
        isLoggedIn: true,
        gamesPlayed: 42,
        currentStreak: 6,
        bestStreak: 18,
        averageScore: 7,
        referencedArticles: articles,
        nextGameCountdownString: "08:24:15"
    )

    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}

#Preview("Logged In 3") {

    let articles: [WMFWhichCameFirstResultsArticle] = [
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
            description: "Earth’s highest mountain above sea level.",
            imageURL: nil
        ),
        .init(
            title: "Printing Press",
            description: "Mechanical device for mass-producing printed text.",
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0c/Gutenberg.jpg")
        )
    ]

    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 3,
        totalQuestions: 5,
        isLoggedIn: true,
        gamesPlayed: 42,
        currentStreak: 6,
        bestStreak: 18,
        averageScore: 7,
        referencedArticles: articles,
        nextGameCountdownString: "08:24:15"
    )

    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}

#Preview("Logged In 4") {

    let articles: [WMFWhichCameFirstResultsArticle] = [
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
            description: "Earth’s highest mountain above sea level.",
            imageURL: nil
        ),
        .init(
            title: "Printing Press",
            description: "Mechanical device for mass-producing printed text.",
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0c/Gutenberg.jpg")
        )
    ]

    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 4,
        totalQuestions: 5,
        isLoggedIn: true,
        gamesPlayed: 42,
        currentStreak: 6,
        bestStreak: 18,
        averageScore: 7,
        referencedArticles: articles,
        nextGameCountdownString: "08:24:15"
    )

    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}

#Preview("Logged In 5") {

    let articles: [WMFWhichCameFirstResultsArticle] = [
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
            description: "Earth’s highest mountain above sea level.",
            imageURL: nil
        ),
        .init(
            title: "Printing Press",
            description: "Mechanical device for mass-producing printed text.",
            imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0c/Gutenberg.jpg")
        )
    ]

    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 5,
        totalQuestions: 5,
        isLoggedIn: true,
        gamesPlayed: 42,
        currentStreak: 6,
        bestStreak: 18,
        averageScore: 7,
        referencedArticles: articles,
        nextGameCountdownString: "08:24:15"
    )

    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}

#Preview("Logged Out") {

    let viewModel = WMFWhichCameFirstResultsViewModel(
        score: 4,
        totalQuestions: 5,
        isLoggedIn: false,
        referencedArticles: [],
        nextGameCountdownString: "08:24:15"
    )

    return WMFWhichCameFirstResultsView(viewModel: viewModel)
}

