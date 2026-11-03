import UIKit
import SwiftUI

public final class WMFReadingListsHostingController: WMFComponentHostingController<WMFReadingListsView> {

    public let viewModel: WMFReadingListsViewModel

    public init(viewModel: WMFReadingListsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFReadingListsView(viewModel: viewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WMFAppEnvironment.current.theme.paperBackground
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        view.backgroundColor = WMFAppEnvironment.current.theme.paperBackground
    }
}
