import UIKit

/// A base Canvas to lay WMFComponents on that automatically subscribes to `AppEnvironment` changes
public class WKCanvas: WKComponentView {

	public override func appEnvironmentDidChange() {
		backgroundColor = WKAppEnvironment.current.theme.paperBackground
	}

}
