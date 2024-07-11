import Foundation
import Combine
import WKData

@objc public class WKDeveloperSettingsLocalizedStrings: NSObject {
    let developerSettings: String
    let doNotPostImageRecommendations: String
    let close: String
    
    @objc public init(developerSettings: String, doNotPostImageRecommendations: String, close: String) {
        self.developerSettings = developerSettings
        self.doNotPostImageRecommendations = doNotPostImageRecommendations
        self.close = close
    }
}

@objc public class WKDeveloperSettingsViewModel: NSObject {
    
    let localizedStrings: WKDeveloperSettingsLocalizedStrings
    let formViewModel: WKFormViewModel
    
    private var subscribers: Set<AnyCancellable> = []
    
    @objc public init(localizedStrings: WKDeveloperSettingsLocalizedStrings) {
        self.localizedStrings = localizedStrings
        let doNotPostImageRecommendationsEditItem = WKFormItemSelectViewModel(title: localizedStrings.doNotPostImageRecommendations, isSelected: WKDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit)
       
        formViewModel = WKFormViewModel(sections: [WKFormSectionSelectViewModel(items: [doNotPostImageRecommendationsEditItem], selectType: .multi)])
        
        doNotPostImageRecommendationsEditItem.$isSelected.sink { isSelected in

            WKDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit = isSelected

        }.store(in: &subscribers)
    }
}
