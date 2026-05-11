import UIKit
import SwiftUI
import WMFData

// MARK: - Hosting Controller

public final class WMFWhichCameFirstHostingController: WMFComponentHostingController<WMFWhichCameFirstView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFWhichCameFirstViewModel

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
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: "Which Came First?",
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
    }

    @objc private func tappedClose() {
        dismiss(animated: true)
    }
}

// MARK: - WMFWhichCameFirstEvent + onThisDayEvent

public extension WMFWhichCameFirstEvent {
    var onThisDayEvent: WMFOnThisDayEvent {
        WMFOnThisDayEvent(
            text: title,
            date: String(year),
            imageURL: thumbnailURL
        )
    }
}
