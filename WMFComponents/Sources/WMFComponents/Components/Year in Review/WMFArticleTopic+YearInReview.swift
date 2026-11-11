import WMFData
import WMFNativeLocalizations

public extension WMFArticleTopic {
    /// The sentence that follows the subtitle on the Year in Review top topic slide.
    var yearInReviewSentence: String {
        switch self {
        case .architecture:
            return CommonStrings.yearInReviewTopTopicSentenceArchitecture
        case .visualArts:
            return CommonStrings.yearInReviewTopTopicSentenceArt
        case .comicsAndAnime:
            return CommonStrings.yearInReviewTopTopicSentenceComicsAndAnime
        case .entertainment:
            return CommonStrings.yearInReviewTopTopicSentenceEntertainment
        case .fashion:
            return CommonStrings.yearInReviewTopTopicSentenceFashion
        case .books:
            return CommonStrings.yearInReviewTopTopicSentenceLiterature
        case .music:
            return CommonStrings.yearInReviewTopTopicSentenceMusic
        case .performingArts:
            return CommonStrings.yearInReviewTopTopicSentencePerformingArts
        case .sports:
            return CommonStrings.yearInReviewTopTopicSentenceSports
        case .films:
            return CommonStrings.yearInReviewTopTopicSentenceTVAndFilm
        case .videoGames:
            return CommonStrings.yearInReviewTopTopicSentenceVideoGames
        case .biography, .women:
            return CommonStrings.yearInReviewTopTopicSentenceBiography
        case .businessAndEconomics:
            return CommonStrings.yearInReviewTopTopicSentenceBusinessAndEconomics
        case .education:
            return CommonStrings.yearInReviewTopTopicSentenceEducation
        case .foodAndDrink:
            return CommonStrings.yearInReviewTopTopicSentenceFoodAndDrink
        case .history:
            return CommonStrings.yearInReviewTopTopicSentenceHistory
        case .militaryAndWarfare:
            return CommonStrings.yearInReviewTopTopicSentenceMilitaryAndWarfare
        case .philosophyAndReligion:
            return CommonStrings.yearInReviewTopTopicSentencePhilosophyAndReligion
        case .politicsAndGovernment:
            return CommonStrings.yearInReviewTopTopicSentencePoliticsAndGovernment
        case .society:
            return CommonStrings.yearInReviewTopTopicSentenceSociety
        case .transportation:
            return CommonStrings.yearInReviewTopTopicSentenceTransportation
        case .biology:
            return CommonStrings.yearInReviewTopTopicSentenceBiology
        case .chemistry:
            return CommonStrings.yearInReviewTopTopicSentenceChemistry
        case .internetCulture:
            return CommonStrings.yearInReviewTopTopicSentenceComputersAndInternet
        case .geographical:
            return CommonStrings.yearInReviewTopTopicSentenceEarthAndEnvironment
        case .engineering:
            return CommonStrings.yearInReviewTopTopicSentenceEngineering
        case .stem:
            return CommonStrings.yearInReviewTopTopicSentenceGeneralScience
        case .mathematics:
            return CommonStrings.yearInReviewTopTopicSentenceMathematics
        case .medicineAndHealth:
            return CommonStrings.yearInReviewTopTopicSentenceMedicineAndHealth
        case .physics:
            return CommonStrings.yearInReviewTopTopicSentencePhysics
        case .technology:
            return CommonStrings.yearInReviewTopTopicSentenceTechnology
        case .africa:
            return CommonStrings.yearInReviewTopTopicSentenceAfrica
        case .asia:
            return CommonStrings.yearInReviewTopTopicSentenceAsia
        case .centralAmerica:
            return CommonStrings.yearInReviewTopTopicSentenceCentralAmerica
        case .europe:
            return CommonStrings.yearInReviewTopTopicSentenceEurope
        case .northAmerica:
            return CommonStrings.yearInReviewTopTopicSentenceNorthAmerica
        case .oceania:
            return CommonStrings.yearInReviewTopTopicSentenceOceania
        case .southAmerica:
            return CommonStrings.yearInReviewTopTopicSentenceSouthAmerica
        }
    }
}
