import UIKit

public final class WMFWikiRunHostingController: WMFComponentHostingController<WMFWikiRunView> {

    public let viewModel: WMFWikiRunViewModel

    public init(viewModel: WMFWikiRunViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFWikiRunView(viewModel: viewModel))
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // The game draws its own chrome; the bar comes back when an article is pushed.
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // Articles enable bar hiding on swipe; leaving it on would re-show the bar over the game.
        navigationController?.hidesBarsOnSwipe = false
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        viewModel.updateTheme()
    }
}
