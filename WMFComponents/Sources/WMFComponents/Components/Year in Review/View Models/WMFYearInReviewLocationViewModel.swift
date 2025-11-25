import Foundation
import WMFData
import CoreLocation
import UIKit

final class WMFYearInReviewSlideLocationViewModel: ObservableObject {
    
    let localizedStrings: WMFYearInReviewViewModel.LocalizedStrings
    let legacyPageViews: [WMFLegacyPageView]
    
    var countryOrOceanName: String
    var randomArticleTitles: [String]
    
    var title: String
    var subtitle: String
    
    let tappedInfo: () -> Void
    let loggingID: String
    
    @Published var isLoading: Bool = true
    var didZoomToLargestCluster = false
    
    var mapViewSnapshotForSharing: UIImage?
    
    let clusterReuseIdentifier = "cluster"
    let clusteringIdentifier = "clusterID"
    let markerReuseIdentifier = "marker"
    
    init(localizedStrings: WMFYearInReviewViewModel.LocalizedStrings, legacyPageViews: [WMFLegacyPageView], loggingID: String, tappedInfo: @escaping () -> Void) {
        self.localizedStrings = localizedStrings
        
        title = ""
        subtitle = ""
        
        countryOrOceanName = ""
        randomArticleTitles = []
        
        self.legacyPageViews = legacyPageViews
        self.tappedInfo = tappedInfo
        self.loggingID = loggingID
        
        isLoading = true
    }
    
    func reverseGeocode(location: CLLocation) {
        
        Task {
            
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            guard let placemark = placemarks.first else {
                return
            }
            
            if let country = placemark.country {
                countryOrOceanName = country
            } else if let ocean = placemark.ocean {
                countryOrOceanName = ocean
            }
            
            title = localizedStrings.personalizedLocationSlideTitle(countryOrOceanName)
            subtitle = localizedStrings.personalizedLocationSlideSubtitle(randomArticleTitles)
            
            Task { @MainActor in
                isLoading = false
            }
        }
    }
}
