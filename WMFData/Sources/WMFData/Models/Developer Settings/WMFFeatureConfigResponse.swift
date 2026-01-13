import Foundation

public struct WMFFeatureConfigResponse: Codable {
    
    public struct Common: Codable {
        public let yir: [YearInReview]
        
        public struct YearInReview: Codable {
            
            public struct TopReadPercentage: Codable {
                public let identifier: String
                public let min: Int
                public let max: Int?
            }
            
            public let year: Int
            public let activeStartDateString: String
            public let activeEndDateString: String
            public let dataStartDateString: String
            public let dataEndDateString: String
            public let languages: Int
            public let articles: Int
            public let savedArticlesApps: Int
            public let viewsApps: Int
            public let editsApps: Int
            public let editsPerMinute: Int
            public let averageArticlesReadPerYear: Int
            public let edits: Int
            public let editsEN: Int
            public let hoursReadEN: Int
            public let yearsReadEN: Int
            public let topReadEN: [String]
            public let topReadPercentages: [TopReadPercentage]
            public let bytesAddedEN: Int
            public let hideCountryCodes: [String]
            public let hideDonateCountryCodes: [String]
            
            enum CodingKeys: String, CodingKey {
                case year
                case activeStartDateString = "activeStartDate"
                case activeEndDateString = "activeEndDate"
                case dataStartDateString = "dataStartDate"
                case dataEndDateString = "dataEndDate"
                case languages
                case articles
                case savedArticlesApps
                case viewsApps
                case editsApps
                case editsPerMinute
                case averageArticlesReadPerYear
                case edits
                case editsEN
                case hoursReadEN
                case yearsReadEN
                case topReadEN
                case topReadPercentages
                case bytesAddedEN
                case hideCountryCodes
                case hideDonateCountryCodes
            }

            var activeStartDate: Date? {
                let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
                return dateFormatter.date(from: activeStartDateString)
            }
            
            var activeEndDate: Date? {
                let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
                return dateFormatter.date(from: activeEndDateString)
            }
            
            var dataStartDate: Date? {
                let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
                return dateFormatter.date(from: dataStartDateString)
            }
            
            var dataEndDate: Date? {
                let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
                return dateFormatter.date(from: dataEndDateString)
            }
            
            func isActive(for date: Date) -> Bool {
                
                // Overwrite date check if developer settings flag is on. This allows us to test outside of active date range.
                let developerSettingsDataController = WMFDeveloperSettingsDataController.shared
                if developerSettingsDataController.showYiRV3 {
                    return true
                }
                
                guard let activeStartDate = activeStartDate, let activeEndDate = activeEndDate else {
                    return false 
                }
                return date >= activeStartDate && date <= activeEndDate
            }
        }
        
        public func yir(year: Int) -> YearInReview? {
            return yir.first { $0.year == year }
        }
        
        public init(yir: [YearInReview]) {
            self.yir = yir
        }
    }
    
    public struct IOS: Codable {
        public let hCaptcha: HCaptcha?
        
        public struct HCaptcha: Codable {
            public let baseURL: String
            public let jsSrc: String
            public let endpoint: String
            public let assethost: String
            public let imghost: String
            public let reportapi: String
            public let sentry: Bool
            public let apiKey: String
        }
    }
    
    public let common: Common
    public let ios: IOS
    var cachedDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case common = "commonv1"
        case ios = "iosv1"
        case cachedDate
    }
    
    public init(common: WMFFeatureConfigResponse.Common, ios: WMFFeatureConfigResponse.IOS, cachedDate: Date? = nil) {
        self.common = common
        self.ios = ios
        self.cachedDate = cachedDate
    }
}
