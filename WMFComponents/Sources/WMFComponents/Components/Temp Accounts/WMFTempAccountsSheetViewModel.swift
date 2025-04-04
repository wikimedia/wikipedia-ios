import Foundation
import SwiftUI
import WMFData

public class WMFTempAccountsSheetViewModel: ObservableObject {
    let image: String
    let title: String
    let subtitle: String
    let ctaTopString: String
    let ctaBottomString: String
    let done: String
    let handleURL: (_ url: URL) -> Void
    let didTapDone: () -> Void
    let ctaTopButtonAction: () -> Void
    let ctaBottomButtonAction: () -> Void
    
    public init(image: String, title: String, subtitle: String, ctaTopString: String, ctaBottomString: String, done: String, handleURL: @escaping (_ url: URL) -> Void, didTapDone: @escaping () -> Void, ctaTopButtonAction: @escaping () -> Void, ctaBottomButtonAction: @escaping () -> Void) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.ctaTopString = ctaTopString
        self.ctaBottomString = ctaBottomString
        self.done = done
        self.handleURL = handleURL
        self.didTapDone = didTapDone
        self.ctaBottomButtonAction = ctaBottomButtonAction
        self.ctaTopButtonAction = ctaTopButtonAction
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
