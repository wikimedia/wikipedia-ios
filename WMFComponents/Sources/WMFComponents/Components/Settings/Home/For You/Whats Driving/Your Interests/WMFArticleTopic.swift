import WMFData
import WMFNativeLocalizations

public extension WMFArticleTopic {
    var displayName: String {
        switch self {
        case .architecture:
            return WMFLocalizedString("article-topic-architecture", value: "Architecture", comment: "Display name for the Architecture article topic.")
        case .visualArts:
            return WMFLocalizedString("article-topic-art", value: "Art", comment: "Display name for the Art article topic.")
        case .comicsAndAnime:
            return WMFLocalizedString("article-topic-comics-and-anime", value: "Comics and anime", comment: "Display name for the Comics and anime article topic.")
        case .entertainment:
            return WMFLocalizedString("article-topic-entertainment", value: "Entertainment", comment: "Display name for the Entertainment article topic.")
        case .fashion:
            return WMFLocalizedString("article-topic-fashion", value: "Fashion", comment: "Display name for the Fashion article topic.")
        case .books:
            return WMFLocalizedString("article-topic-literature", value: "Literature", comment: "Display name for the Literature article topic.")
        case .music:
            return WMFLocalizedString("article-topic-music", value: "Music", comment: "Display name for the Music article topic.")
        case .performingArts:
            return WMFLocalizedString("article-topic-performing-arts", value: "Performing arts", comment: "Display name for the Performing arts article topic.")
        case .sports:
            return WMFLocalizedString("article-topic-sports", value: "Sports", comment: "Display name for the Sports article topic.")
        case .films:
            return WMFLocalizedString("article-topic-tv-and-film", value: "TV and film", comment: "Display name for the TV and film article topic.")
        case .videoGames:
            return WMFLocalizedString("article-topic-video-games", value: "Video games", comment: "Display name for the Video games article topic.")
        case .biography:
            return WMFLocalizedString("article-topic-biography", value: "Biography (all)", comment: "Display name for the Biography (all) article topic.")
        case .women:
            return WMFLocalizedString("article-topic-women", value: "Biography (women)", comment: "Display name for the Biography (women) article topic.")
        case .businessAndEconomics:
            return WMFLocalizedString("article-topic-business-and-economics", value: "Business and economics", comment: "Display name for the Business and economics article topic.")
        case .education:
            return WMFLocalizedString("article-topic-education", value: "Education", comment: "Display name for the Education article topic.")
        case .foodAndDrink:
            return WMFLocalizedString("article-topic-food-and-drink", value: "Food and drink", comment: "Display name for the Food and drink article topic.")
        case .history:
            return WMFLocalizedString("article-topic-history", value: "History", comment: "Display name for the History article topic.")
        case .militaryAndWarfare:
            return WMFLocalizedString("article-topic-military-and-warfare", value: "Military and warfare", comment: "Display name for the Military and warfare article topic.")
        case .philosophyAndReligion:
            return WMFLocalizedString("article-topic-philosophy-and-religion", value: "Philosophy and religion", comment: "Display name for the Philosophy and religion article topic.")
        case .politicsAndGovernment:
            return WMFLocalizedString("article-topic-politics-and-government", value: "Politics and government", comment: "Display name for the Politics and government article topic.")
        case .society:
            return WMFLocalizedString("article-topic-society", value: "Society", comment: "Display name for the Society article topic.")
        case .transportation:
            return WMFLocalizedString("article-topic-transportation", value: "Transportation", comment: "Display name for the Transportation article topic.")
        case .biology:
            return WMFLocalizedString("article-topic-biology", value: "Biology", comment: "Display name for the Biology article topic.")
        case .chemistry:
            return WMFLocalizedString("article-topic-chemistry", value: "Chemistry", comment: "Display name for the Chemistry article topic.")
        case .internetCulture:
            return WMFLocalizedString("article-topic-computers-and-internet", value: "Computers and internet", comment: "Display name for the Computers and internet article topic.")
        case .geographical:
            return WMFLocalizedString("article-topic-earth-and-environment", value: "Earth and environment", comment: "Display name for the Earth and environment article topic.")
        case .engineering:
            return WMFLocalizedString("article-topic-engineering", value: "Engineering", comment: "Display name for the Engineering article topic.")
        case .stem:
            return WMFLocalizedString("article-topic-general-science", value: "General science", comment: "Display name for the General science article topic.")
        case .mathematics:
            return WMFLocalizedString("article-topic-mathematics", value: "Mathematics", comment: "Display name for the Mathematics article topic.")
        case .medicineAndHealth:
            return WMFLocalizedString("article-topic-medicine-and-health", value: "Medicine and health", comment: "Display name for the Medicine and health article topic.")
        case .physics:
            return WMFLocalizedString("article-topic-physics", value: "Physics", comment: "Display name for the Physics article topic.")
        case .technology:
            return WMFLocalizedString("article-topic-technology", value: "Technology", comment: "Display name for the Technology article topic.")
        case .africa:
            return WMFLocalizedString("article-topic-africa", value: "Africa", comment: "Display name for the Africa article topic.")
        case .asia:
            return WMFLocalizedString("article-topic-asia", value: "Asia", comment: "Display name for the Asia article topic.")
        case .centralAmerica:
            return WMFLocalizedString("article-topic-central-america", value: "Central America", comment: "Display name for the Central America article topic.")
        case .europe:
            return WMFLocalizedString("article-topic-europe", value: "Europe", comment: "Display name for the Europe article topic.")
        case .northAmerica:
            return WMFLocalizedString("article-topic-north-america", value: "North America", comment: "Display name for the North America article topic.")
        case .oceania:
            return WMFLocalizedString("article-topic-oceania", value: "Oceania", comment: "Display name for the Oceania article topic.")
        case .southAmerica:
            return WMFLocalizedString("article-topic-south-america", value: "South America", comment: "Display name for the South America article topic.")
        }
    }
}
