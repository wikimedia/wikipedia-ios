import UIKit
import WMFNativeLocalizations
import SwiftUI
import WMFData
import Foundation

// MARK: - Hosting Controller


public final class WMFWhichCameFirstHostingController: WMFComponentHostingController<WMFWhichCameFirstView>, WMFNavigationBarConfiguring {

    public let viewModel: WMFWhichCameFirstViewModel
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    
    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }

    private lazy var moreBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .ellipsis), primaryAction: nil, menu: overflowMenu)
        button.accessibilityLabel = CommonStrings.moreButton
        return button
    }()

    private var overflowMenu: UIMenu {
        let learnMoreAction = UIAction(
            title: CommonStrings.learnMoreTitle(),
            image: WMFSFSymbolIcon.for(symbol: .infoCircle)
        ) { [weak self] _ in
            self?.viewModel.didTapLearnMore?()
        }
        let reportProblemAction = UIAction(
            title: CommonStrings.problemWithFeatureTitle,
            image: WMFSFSymbolIcon.for(symbol: .flag)
        ) { [weak self] _ in
            self?.viewModel.didTapReportProblem?()
        }
        return UIMenu(title: String(), options: .displayInline, children: [learnMoreAction, reportProblemAction])
    }

    public init(viewModel: WMFWhichCameFirstViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFWhichCameFirstView(viewModel: viewModel))
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        viewModel.load()
        viewModel.onDateChanged = { [weak self] in
            self?.configureNavigationBar()
        }
        (self.navigationController as? WMFComponentNavigationController)?.turnOnForcePortrait()
    }
    

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: DateFormatter.wmfMonthDayFromDailyGameDate(viewModel.date),
            customView: nil,
            alignment: .centerCompact
        )
        let closeConfig = WMFLargeCloseButtonConfig(
            imageType: .plainX,
            target: self,
            action: #selector(tappedClose),
            alignment: .leading
        )
        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )

        navigationItem.rightBarButtonItem = moreBarButtonItem

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = WMFAppEnvironment.current.theme.link
        appearance.titleTextAttributes = [.foregroundColor: theme.baseBackground]
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = theme.baseBackground
        (self.navigationController as? WMFComponentNavigationController)?.turnOnForcePortrait()
    }

    @objc private func tappedClose() {
        viewModel.didTapExitDuringPlay?(viewModel.currentIndex + 1, viewModel.phase == .complete)
        dismiss(animated: true)
    }
}
