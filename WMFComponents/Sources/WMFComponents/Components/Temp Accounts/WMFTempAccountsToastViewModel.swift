import Foundation
import SwiftUI
import WMFData

public class WMFTempAccountsToastViewModel: ObservableObject {
    public var didTapReadMore: () -> Void
    public var didTapClose: () -> Void
    
    public init(didTapReadMore: @escaping () -> Void, didTapClose: @escaping () -> Void) {
        self.didTapReadMore = didTapReadMore
        self.didTapClose = didTapClose
    }
}
