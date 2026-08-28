import Foundation
import UIKit

fileprivate final class WMFDonationReminderSetupHostingController: WMFComponentHostingController<WMFDonationReminderSetupView> {

}

public final class WMFDonationReminderSetupViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {

    // MARK: - Properties

    private let hostingViewController: WMFDonationReminderSetupHostingController
    private let viewModel: WMFDonationReminderSetupViewModel

    // MARK: - Lifecycle

    public init(viewModel: WMFDonationReminderSetupViewModel) {
        self.viewModel = viewModel
        let view = WMFDonationReminderSetupView(viewModel: viewModel)
        self.hostingViewController = WMFDonationReminderSetupHostingController(rootView: view)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        addComponent(hostingViewController, pinToEdges: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "", customView: nil, alignment: .centerCompact)
        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: nil,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
        navigationItem.rightBarButtonItem = moreBarButtonItem
    }

    private lazy var moreBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .ellipsis), primaryAction: nil, menu: overflowMenu)
        button.accessibilityLabel = viewModel.localizedStrings.moreButtonAccessibilityLabel
        return button
    }()

    private var overflowMenu: UIMenu {
        let learnMoreAction = UIAction(
            title: viewModel.localizedStrings.learnMoreButtonTitle,
            image: WMFSFSymbolIcon.for(symbol: .infoCircle)
        ) { [weak self] _ in
            self?.viewModel.didTapAboutExperiment?()
        }

        let reportProblemAction = UIAction(
            title: viewModel.localizedStrings.problemWithFeatureButtonTitle,
            image: WMFSFSymbolIcon.for(symbol: .flag)
        ) { [weak self] _ in
            self?.viewModel.didTapReportProblem?()
        }

        return UIMenu(title: String(), options: .displayInline, children: [learnMoreAction, reportProblemAction])
    }
}
