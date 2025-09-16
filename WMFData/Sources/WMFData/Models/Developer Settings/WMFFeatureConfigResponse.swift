import Foundation

public struct WMFFeatureConfigResponse: Codable {
    public struct IOS: Codable {
        
        public let yir: [YearInReview]
        public struct YearInReview: Codable {
            
            public struct PersonalizedSlides: Codable {
                let readCount: SlideSettings
                let editCount: SlideSettings
                let donateCount: SlideSettings
                let saveCount: SlideSettings
                let mostReadDate: SlideSettings
                let viewCount: SlideSettings
                let mostReadArticles: SlideSettings
                let mostReadCategories: SlideSettings
                let locationArticles: SlideSettings
            }
            
            public struct SlideSettings: Codable {
                public let isEnabled: Bool
            }
            
            public let yearID: String
            public let isEnabled: Bool
            public let countryCodes: [String]
            public let primaryAppLanguageCodes: [String]
            public let dataPopulationStartDateString: String
            public let dataPopulationEndDateString: String
            public let personalizedSlides: PersonalizedSlides
            public let hideDonateCountryCodes: [String]

            var dataPopulationStartDate: Date? {
                let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
                return dateFormatter.date(from: dataPopulationStartDateString)
            }
            
            var dataPopulationEndDate: Date? {
                let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
                return dateFormatter.date(from: dataPopulationEndDateString)
            }
        }
        
        public func yir(yearID: String) -> YearInReview? {
            return yir.first { $0.yearID == yearID }
        }
        
        public init(yir: [YearInReview]) {
            self.yir = yir
        }
    }
    
    public let ios: IOS
    var cachedDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case ios = "iosv1"
        case cachedDate
    }
    
    public init(ios: WMFFeatureConfigResponse.IOS, cachedDate: Date? = nil) {
        self.ios = ios
        self.cachedDate = cachedDate
    }
}
