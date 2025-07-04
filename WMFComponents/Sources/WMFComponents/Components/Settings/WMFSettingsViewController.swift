import UIKit
import SwiftUI
import Combine

fileprivate final class WMFSettingsHostingController: WMFComponentHostingController<WMFSettingsView> {}

final public class WMFSettingsViewControllerNEW: WMFCanvasViewController, WMFNavigationBarConfiguring {

    private let hostingViewController: WMFSettingsHostingController

    public override init() {
        // MOCK SECTIONS
        let viewModel = WMFSettingsViewModel(sections: [])

        let notificationsBinding = Binding<Bool>(
            get: { viewModel.notificationsOn },
            set: { viewModel.notificationsOn = $0 }
        )
        let exploreFeedBinding = Binding<Bool>(
            get: { viewModel.exploreFeedOn },
            set: { viewModel.exploreFeedOn = $0 }
        )

        let isSelected = Binding<Bool>(
            get: { viewModel.isWhateverSelected },
            set: { viewModel.isWhateverSelected = $0 }
            )

        let sections: [SettingsSection] = [
            SettingsSection(
                header: "General",
                footer: "Your core preferences",
                items: [
                    SettingsItem(
                        image: UIImage(systemName: "bell"),
                        color: WMFColor.red700,
                        title: "Notifications",
                        subtitle: "Receive updates",
                        accessory: .toggle(notificationsBinding),
                        action: nil,
                        subSections: nil
                    ),
                    SettingsItem(
                        image: UIImage(systemName: "globe"),
                        color: WMFColor.blue300,
                        title: "Explore feed",
                        subtitle: "Show recommended articles",
                        accessory: .toggle(exploreFeedBinding),
                        action: nil,
                        subSections: nil
                    ),
                    SettingsItem(
                        image: UIImage(systemName: "gear"),
                        color: WMFColor.gray100,
                        title: "Advanced…",
                        subtitle: nil,
                        accessory: .label("PT"),
                        action: nil,
                        subSections: [
                            SettingsSection(
                                header: "Advanced Settings",
                                footer: nil,
                                items: [
                                    SettingsItem(
                                        image: UIImage(systemName: "lock"),
                                        color: WMFColor.yellow600,
                                        title: "Privacy",
                                        subtitle: nil,
                                        accessory: .toggle(isSelected),
                                        action: nil,
                                        subSections: nil
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]

        viewModel.sections = sections

        self.hostingViewController = WMFSettingsHostingController(
            rootView: WMFSettingsView(viewModel: viewModel)
            
        )
        super.init()
    }

    @MainActor required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addComponent(hostingViewController, pinToEdges: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: "Settings",
            customView: nil,
            alignment: .leadingCompact
        )
        let closeConfig = WMFNavigationBarCloseButtonConfig(
            text: "done",
            target: self,
            action: #selector(tappedDone),
            alignment: .trailing
        )
        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
    }

    @objc func tappedDone() {
        dismiss(animated: true)
    }
}
