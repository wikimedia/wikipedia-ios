import Foundation

public extension WMFArticleTopic {

    /// Makes the topic for a label that the Page Content Service stores on an article (see `WMFPageTopic`).
    ///
    /// The labels come from the ORES article topic taxonomy, for example "STEM.Biology",
    /// "History_and_Society.Military_and_warfare" or "Geography.Regions.Asia.East_Asia". The table
    /// follows the CirrusSearch `articletopic:` mapping. Some labels go to the topic that has the
    /// same display name, because the topic list has fewer topics than the taxonomy: for example
    /// "Culture.Media.Television" goes to `.films` ("TV and film").
    ///
    /// Returns `nil` for a label that has no topic, for example "Culture.Linguistics" or "STEM.Space".
    init?(pageTopicLabel: String) {
        let label = Self.normalizedPageTopicLabel(pageTopicLabel)

        if let topic = Self.topicsByPageTopicLabel[label] {
            self = topic
            return
        }

        // A region label can name a subregion, for example "Geography.Regions.Europe.Western Europe".
        // Each subregion goes to its continent.
        if let topic = Self.topicsByRegionPrefix.first(where: { label.hasPrefix($0.prefix) })?.topic {
            self = topic
            return
        }

        return nil
    }

    /// Underscores become spaces, and the trailing "*" that marks a parent topic is removed.
    private static func normalizedPageTopicLabel(_ label: String) -> String {
        var normalized = label.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "_", with: " ")
        if normalized.hasSuffix("*") {
            normalized.removeLast()
        }
        return normalized
    }

    private static let topicsByPageTopicLabel: [String: WMFArticleTopic] = [
        // Culture
        "Culture.Visual arts.Architecture": .architecture,
        "Culture.Visual arts.Visual arts": .visualArts,
        "Culture.Visual arts.Comics and Anime": .comicsAndAnime,
        "Culture.Visual arts.Fashion": .fashion,
        "Culture.Media.Entertainment": .entertainment,
        "Culture.Media.Books": .books,
        "Culture.Literature": .books,
        "Culture.Media.Music": .music,
        "Culture.Performing arts": .performingArts,
        "Culture.Sports": .sports,
        "Culture.Media.Films": .films,
        "Culture.Media.Television": .films,
        "Culture.Media.Video games": .videoGames,
        "Culture.Biography.Biography": .biography,
        "Culture.Biography.Women": .women,
        "Culture.Food and drink": .foodAndDrink,
        "Culture.Philosophy and religion": .philosophyAndReligion,
        "Culture.Internet culture": .internetCulture,
        "Culture.Media.Software": .internetCulture,

        // History and society
        "History and Society.Business and economics": .businessAndEconomics,
        "History and Society.Education": .education,
        "History and Society.History": .history,
        "History and Society.Military and warfare": .militaryAndWarfare,
        "History and Society.Politics and government": .politicsAndGovernment,
        "History and Society.Society": .society,
        "History and Society.Transportation": .transportation,

        // STEM
        "STEM.Biology": .biology,
        "STEM.Chemistry": .chemistry,
        "STEM.Computing": .internetCulture,
        "STEM.Earth and environment": .geographical,
        "Geography.Geographical": .geographical,
        "STEM.Engineering": .engineering,
        "STEM.STEM": .stem,
        "STEM.Mathematics": .mathematics,
        "STEM.Medicine & Health": .medicineAndHealth,
        "STEM.Physics": .physics,
        "STEM.Technology": .technology,

        // Regions
        "Geography.Regions.Americas.Central America": .centralAmerica,
        "Geography.Regions.Americas.North America": .northAmerica,
        "Geography.Regions.Americas.South America": .southAmerica,
        "Geography.Regions.Oceania": .oceania
    ]

    private static let topicsByRegionPrefix: [(prefix: String, topic: WMFArticleTopic)] = [
        ("Geography.Regions.Africa.", .africa),
        ("Geography.Regions.Asia.", .asia),
        ("Geography.Regions.Europe.", .europe)
    ]
}
