import UIKit
import SwiftUI
import WMFData
import CocoaLumberjackSwift
import WMFComponents
import WMF

final class WMFActivityTabHostingController: WMFComponentHostingController<WMFActivityView> {

}

@objc public final class WMFActivityTabViewController: WMFCanvasViewController, Themeable, WMFNavigationBarConfiguring {
    public func apply(theme: WMF.Theme) {
        guard viewIfLoaded != nil else {
            return
        }

        self.theme = theme
        profileCoordinator?.theme = theme
        
        updateProfileButton()
    }
    
    public let viewModel: WMFActivityViewModel
    public let showSurvey: () -> Void
    private let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
    public let dataStore: MWKDataStore?
    var theme: Theme
    
    public init(viewModel: WMFActivityViewModel, theme: Theme, showSurvey: @escaping () -> Void, profileButtonConfig: WMFNavigationBarProfileButtonConfig? = nil, dataStore: MWKDataStore) {
        self.viewModel = viewModel
        self.showSurvey = showSurvey
        self.theme = theme
        let view = WMFActivityView(viewModel: viewModel)
        self.hostingViewController = WMFActivityTabHostingController(rootView: view)
        self.profileButtonConfig = profileButtonConfig
        self.dataStore = dataStore
        super.init()
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let hostingViewController: WMFActivityTabHostingController
    
    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        addComponent(hostingViewController, pinToEdges: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureNavigationBar()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let isLoggedIn = dataStore?.authenticationManager.authStateIsPermanent, isLoggedIn == true {
            let defaults = UserDefaults.standard
            let key = "viewedActivityTab"
            
            if defaults.object(forKey: key) == nil {
                defaults.set(1, forKey: key)
            } else {
                let currentValue = defaults.integer(forKey: key)
                if currentValue == 1 {
                    defaults.set(2, forKey: key)
                    showSurvey()
                }
            }
        }
        
        if let wmfProject = viewModel.project {
            if viewModel.isLoggedIn {
                EditInteractionFunnel.shared.logActivityTabDidAppear(project: WikimediaProject(wmfProject: wmfProject))
            } else {
                EditInteractionFunnel.shared.logActivityTabLoggedOutDidAppear(project: WikimediaProject(wmfProject: wmfProject))
            }
        }
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.activityTitle, customView: nil, alignment: .leadingCompact)
        let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
        if let dataStore {
            profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController,  leadingBarButtonItem: nil)
        } else {
            profileButtonConfig = nil
        }
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc func userDidTapProfile() {
        
        guard let dataStore else {
            return
        }
        
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let metricsID = DonateCoordinator.metricsID(for: .savedProfile, languageCode: languageCode) else {
            return
        }
        
        DonateFunnel.shared.logSavedProfile(metricsID: metricsID)
              
        profileCoordinator?.start()
    }
    
    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {
        
        guard let navigationController,
        let yirCoordinator = self.yirCoordinator,
            let dataStore else {
            return nil
        }
        
        guard let existingProfileCoordinator = _profileCoordinator else {
            _profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .savedProfile, logoutDelegate: self, sourcePage: ProfileCoordinatorSource.saved, yirCoordinator: yirCoordinator)
            _profileCoordinator?.badgeDelegate = self
            return _profileCoordinator
        }
        
        return existingProfileCoordinator
    }
    
    private var _yirCoordinator: YearInReviewCoordinator?
    var yirCoordinator: YearInReviewCoordinator? {
        
        guard let navigationController,
              let yirDataController,
              let dataStore else {
            return nil
        }

        guard let existingYirCoordinator = _yirCoordinator else {
            _yirCoordinator = YearInReviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, dataController: yirDataController)
            _yirCoordinator?.badgeDelegate = self
            return _yirCoordinator
        }
        
        return existingYirCoordinator
    }
    
    private func updateProfileButton() {
        
        guard let dataStore else {
            return
        }
        
        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }
}

extension WMFActivityTabViewController: YearInReviewBadgeDelegate {
    public func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}

extension WMFActivityTabViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {
        
        guard let dataStore else {
            return
        }
        
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }
}
