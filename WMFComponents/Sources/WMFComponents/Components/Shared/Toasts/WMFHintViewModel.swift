import SwiftUI

@MainActor
public class WMFHintViewModel: ObservableObject {
    @Published public var title: String
    @Published public var subtitle: String?
    @Published public var icon: UIImage?
    @Published public var buttonTitle: String?
    
    public var duration: TimeInterval?
    public var tapAction: (() -> Void)?
    public var buttonAction: (() -> Void)?
    
    public init(config: WMFHintConfig) {
        self.title = config.title
        self.subtitle = config.subtitle
        self.icon = config.icon
        self.buttonTitle = config.buttonTitle
        self.duration = config.duration
        self.tapAction = config.tapAction
        self.buttonAction = config.buttonAction
    }
    
    public func update(config: WMFHintConfig) {
        print("🔍 WMFHintViewModel.update called")
        print("🔍 Old title: \(self.title)")
        print("🔍 New title: \(config.title)")
        print("🔍 Old icon: \(self.icon != nil), New icon: \(config.icon != nil)")
        
        self.title = config.title
        self.subtitle = config.subtitle
        self.icon = config.icon
        self.buttonTitle = config.buttonTitle
        self.duration = config.duration
        self.tapAction = config.tapAction
        self.buttonAction = config.buttonAction
        
        print("🔍 Update applied - objectWillChange should fire")
    }
}
