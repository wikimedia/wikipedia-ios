import UIKit
import SwiftUI
import WMFComponents
import WMFData

class WMFNewArticleTabsSettingsViewController: UIViewController {
    private var hostingController: UIHostingController<WMFNewArticleTabSettingsView>?
    private var viewModel: WMFNewArticleTabSettingsViewModel?
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    let dataController = WMFArticleTabsDataController()
    private var initialIndex: Int
    private var theme: Theme
    
    @objc init(theme: Theme) {
        self.theme = theme
        
        let isBYREnabled = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsBYR.rawValue)) ?? false
        let isDYKEnabled = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsDYK.rawValue)) ?? false

        if isBYREnabled {
            initialIndex = 0
        } else if isDYKEnabled {
            initialIndex = 1
        } else {
            initialIndex = 0
        }
        
        super.init(nibName: nil, bundle: nil)
    }

    private func tagToKey(_ tag: Int) -> String {
        switch tag {
        case 0:
            return WMFUserDefaultsKey.developerSettingsMoreDynamicTabsBYR.rawValue
        case 1:
            return WMFUserDefaultsKey.developerSettingsMoreDynamicTabsDYK.rawValue
        default:
            return ""
        }
    }
    
    private func saveSelection(selectedIndex: Int) {
        let isBYR = selectedIndex == 0
        let isDYK = selectedIndex == 1

        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsBYR.rawValue, value: isBYR)
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsDYK.rawValue, value: isDYK)

        dataController.moreDynamicTabsBYRIsEnabled = isBYR
        dataController.moreDynamicTabsDYKIsEnabled = isDYK
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewModel = WMFNewArticleTabSettingsViewModel(
            title: CommonStrings.tabsPreferencesTitle,
            header: CommonStrings.newTabTheme,
            options: [
                CommonStrings.recommendations,
                CommonStrings.didyouknow
            ],
            saveSelection: { [weak self] selectedIndex in
                self?.saveSelection(selectedIndex: selectedIndex)
            },
            selectedIndex: initialIndex, loggingDelegate: self
        )

        guard let viewModel else { return }
        
        self.title = viewModel.title

        let swiftUIView = WMFNewArticleTabSettingsView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: swiftUIView)
        self.hostingController = hostingController

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}

extension WMFNewArticleTabsSettingsViewController: WMFNewArticleTabSettingsLoggingDelegate {
    func logPreference(index: Int) {
        ArticleTabsFunnel.shared.logTabsPreferenceClick(action: index == 0 ? .recommendationPrefClick : .didYouKnowPrefClick)
    }

}
