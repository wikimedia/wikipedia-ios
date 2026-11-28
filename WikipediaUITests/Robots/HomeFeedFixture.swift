import Foundation

/// The fixture content the Home feed tests rely on, per fixture language.
///
/// Community: `ArticleControls/<language>/DogFeedResponse.json` keeps the Dog article as the featured
/// article and as the first Top read article, so both open a fully fixture-backed article. The
/// other modules come from the live feed of each wiki. The Hebrew and Vietnamese wikis have no
/// On this day, so their feeds have no On this day module.
///
/// For You: the topic search for every language answers with `Onboarding/en/OnboardingRandomArticles.json`.
/// The app puts its articles with a thumbnail in the first two card slots, in the order of the
/// response, so the first two cards of the interest module are always the same.
struct HomeFeedFixture {
    let featuredArticleTitle: String
    let hasOnThisDay: Bool

    /// The number of stories in the In the news module.
    static let newsStoryCount = 2

    static let firstForYouCardTitle = "Armavir Province"
    static let secondForYouCardTitle = "Vatera"

    static func fixture(languageCode: String) -> HomeFeedFixture? {
        switch languageCode {
        case "en":
            return HomeFeedFixture(featuredArticleTitle: "Dog", hasOnThisDay: true)
        case "de":
            return HomeFeedFixture(featuredArticleTitle: "Haushund", hasOnThisDay: true)
        case "he":
            return HomeFeedFixture(featuredArticleTitle: "כלב הבית", hasOnThisDay: false)
        case "vi":
            return HomeFeedFixture(featuredArticleTitle: "Chó", hasOnThisDay: false)
        default:
            return nil
        }
    }
}
