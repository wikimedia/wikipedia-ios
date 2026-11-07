import Foundation

extension WMFArticleTopic {

    /// The Wikimedia Commons file with the Year in Review illustration of the topic, from
    /// https://commons.wikimedia.org/wiki/Category:Wikipedia_Year_in_Review_2026. All the regions
    /// use the same file.
    var yearInReviewIllustrationFileName: String {
        switch self {
        case .architecture: return "01 Architecture.png"
        case .visualArts: return "02 Art.png"
        case .comicsAndAnime: return "03 Comics Anime.png"
        case .entertainment: return "04 Entertainment.png"
        case .fashion: return "05 Fashion.png"
        case .books: return "06 Literature.png"
        case .music: return "07 Music.png"
        case .performingArts: return "08 Performing Arts.png"
        case .sports: return "09 Sports.png"
        case .films: return "10 TV Film.png"
        case .videoGames: return "11 Videogames.png"
        case .biography: return "12 Biography all.png"
        case .women: return "13 Biography women.png"
        case .businessAndEconomics: return "14 Business Economics.png"
        case .education: return "15 Education.png"
        case .foodAndDrink: return "16 Food Drink.png"
        case .history: return "17 History.png"
        case .militaryAndWarfare: return "18 Military warfare.png"
        case .philosophyAndReligion: return "19 Religion Philosophy.png"
        case .politicsAndGovernment: return "20 Politics Government.png"
        case .society: return "21 Society.png"
        case .transportation: return "22 Transportation.png"
        case .biology: return "23 Biology.png"
        case .chemistry: return "24 Chemistry.png"
        case .internetCulture: return "25 Computers Internet.png"
        case .geographical: return "26 Earth Environment.png"
        case .engineering: return "27 Engineering.png"
        case .stem: return "28 General Science.png"
        case .mathematics: return "29 Mathematics.png"
        case .medicineAndHealth: return "30 Medicine Health.png"
        case .physics: return "31 Physics.png"
        case .technology: return "32 Technology.png"
        case .africa, .asia, .centralAmerica, .europe, .northAmerica, .oceania, .southAmerica:
            return "33 - 39 Regional.png"
        }
    }
}
