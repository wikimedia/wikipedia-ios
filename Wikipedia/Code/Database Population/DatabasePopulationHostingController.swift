import SwiftUI
import WMFComponents
import WMFData
import WMF

final class DatabasePopulationHostingController: WMFComponentHostingController<DatabasePopulationView>, WMFNavigationBarConfiguring {

    public init() {
        let view = DatabasePopulationView()
        super.init(rootView: view)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: "Database Population",
            customView: nil,
            alignment: .leadingLarge
        )

        let closeConfig = WMFNavigationBarCloseButtonConfig(
            text: CommonStrings.doneTitle,
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

    @objc private func tappedDone() {
        dismiss(animated: true)
    }
}
