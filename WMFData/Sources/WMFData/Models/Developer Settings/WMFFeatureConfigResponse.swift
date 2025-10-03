import Foundation

public struct WMFFeatureConfigResponse: Codable {
    
    public struct Common: Codable {
        public let yir: [YearInReview]
        
        public struct YearInReview: Codable {
            
            public let year: Int
            public let activeStartDateString: String
            public let activeEndDateString: String
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
            public let bytesAddedEN: Int
            public let hideCountryCodes: [String]
            public let hideDonateCountryCodes: [String]
            
            enum CodingKeys: String, CodingKey {
                case year
                case activeStartDateString = "activeStartDate"
                case activeEndDateString = "activeEndDate"
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
            
            var dataPopulationStartDate: Date? {
                var startComponents = DateComponents()
                    startComponents.year = year
                    startComponents.month = 1
                    startComponents.day = 1
                    startComponents.hour = 0
                    startComponents.minute = 0
                    startComponents.second = 0
                return Calendar.current.date(from: startComponents)
            }
            
            var dataPopulationEndDate: Date? {
                var startComponents = DateComponents()
                    startComponents.year = year
                    startComponents.month = 12
                    startComponents.day = 31
                    startComponents.hour = 23
                    startComponents.minute = 59
                    startComponents.second = 59
                return Calendar.current.date(from: startComponents)
            }
            
            var dataPopulationStartDateString: String? {
                if let dataPopulationStartDate {
                    let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
                    return dateFormatter.string(from: dataPopulationStartDate)
                }
                
                return nil
            }
            
            var dataPopulationEndDateString: String? {
                if let dataPopulationEndDate {
                    let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
                    return dateFormatter.string(from: dataPopulationEndDate)
                }
                
                return nil
            }
            
            func isActive(for date: Date) -> Bool {
                
                // Overwrite date check if developer settings flag is on. This allows us to test outside of active date range.
                let developerSettingsDataController = WMFDeveloperSettingsDataController.shared
                if developerSettingsDataController.showYiRV2 ||
                    developerSettingsDataController.showYiRV3 {
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
