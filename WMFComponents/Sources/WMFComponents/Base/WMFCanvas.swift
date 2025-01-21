import UIKit

/// A base Canvas to lay WMFComponents on that automatically subscribes to `AppEnvironment` changes
public class WMFCanvas: WMFComponentView {

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        backgroundColor = WMFAppEnvironment.current.theme.paperBackground
    }

}
