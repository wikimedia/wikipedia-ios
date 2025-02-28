import Foundation
import SwiftUI
import WMFData

public class WMFTempAccountsToastViewModel: ObservableObject {
    public var didTapReadMore: () -> Void
    public var title: String
    public var readMoreButtonTitle: String
    
    public init(didTapReadMore: @escaping () -> Void, title: String, readMoreButtonTitle: String) {
        self.didTapReadMore = didTapReadMore
        self.title = title
        self.readMoreButtonTitle = readMoreButtonTitle
    }
}
