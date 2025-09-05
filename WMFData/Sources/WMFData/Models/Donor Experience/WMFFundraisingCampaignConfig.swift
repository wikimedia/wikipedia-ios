import Foundation

public struct WMFFundraisingCampaignConfig {
 
 public struct WMFAsset {
     
     public struct WMFAction {
         public let title: String
         public let url: URL?
     }
     
     public let id: String // Matches parent id
     public let assetID: String? // Populated if asset is a part of an A/B test
     public let textHtml: String
     public let footerHtml: String
     public let actions: [WMFAction]
     public let countryCode: String
     public let currencyCode: String
     public let startDate: Date
     public let endDate: Date
     public let languageCode: String
 }
 
 public let id: String
 public let assets: [String: WMFAsset]
}
