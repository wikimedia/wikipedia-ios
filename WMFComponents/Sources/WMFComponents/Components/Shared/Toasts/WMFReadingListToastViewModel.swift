import SwiftUI

@MainActor
public class WMFReadingListToastViewModel: ObservableObject {
    @Published public var title: String
    @Published public var icon: UIImage?
    @Published public var buttonTitle: String?
    
    public var duration: TimeInterval?
    public var tapAction: (() -> Void)?
    public var buttonAction: (() -> Void)?
    
    public init(config: WMFReadingListToastConfig) {
        self.title = config.title
        self.icon = config.icon
        self.buttonTitle = config.buttonTitle
        self.duration = config.duration
        self.tapAction = config.tapAction
        self.buttonAction = config.buttonAction
    }
    
    public func update(config: WMFReadingListToastConfig) {
        self.title = config.title
        self.icon = config.icon
        self.buttonTitle = config.buttonTitle
        self.duration = config.duration
        self.tapAction = config.tapAction
        self.buttonAction = config.buttonAction
    }
}
