import UIKit
import SwiftUI

public struct WMFHomeFeedSettingsView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    let placeholderText: String

    public init(placeholderText: String) {
        self.placeholderText = placeholderText
    }

    public var body: some View {
        VStack {
            Spacer()
            // Temporary blank UI until the Home feed settings are built out.
            Text(placeholderText)
                .font(Font(WMFFont.for(.headline)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: theme.paperBackground))
        .environment(\.colorScheme, theme.preferredColorScheme)
    }
}

public final class WMFHomeFeedSettingsViewController: WMFComponentHostingController<WMFHomeFeedSettingsView>, WMFNavigationBarConfiguring {

    private let pageTitle: String

    public init(title: String) {
        self.pageTitle = title
        super.init(rootView: WMFHomeFeedSettingsView(placeholderText: title))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: pageTitle, customView: nil, alignment: .centerCompact)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
}
