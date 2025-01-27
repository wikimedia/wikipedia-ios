import Foundation
import SwiftUI
import WMFData

public class WMFTempAccountsSheetViewModel: ObservableObject {
    let image: String
    let title: String
    let subtitle: AttributedString
    let ctaTopString: String
    let ctaBottomString: String
    // let ctaTopAction: () -> ()
    
    public init(image: String, title: String, subtitle: AttributedString, ctaTopString: String, ctaBottomString: String) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.ctaTopString = ctaTopString
        self.ctaBottomString = ctaBottomString
    }
    
    public struct LocalizedStrings {
        let title: String
        let subtitle: String
        let cta1: String
        let cta2: String
        
        public init(title: String, subtitle: String, cta1: String, cta2: String) {
            self.title = title
            self.subtitle = subtitle
            self.cta1 = cta1
            self.cta2 = cta2
        }
    }
}
