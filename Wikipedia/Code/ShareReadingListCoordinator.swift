import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import CocoaLumberjackSwift

/// Shares a reading list as one link to Special:ReadingLists, like the Android app. The link imports the list in the apps and on the web.
final class ShareReadingListCoordinator: Coordinator {

    let navigationController: UINavigationController
    private let pages: [WMFShareReadingListDataController.Page]
    private let listName: String
    private let sourceRect: CGRect
    private var shareTask: Task<Void, Never>?

    /// - Parameters:
    ///   - listName: The subject of the share, for example in Mail.
    ///   - sourceRect: The frame the iPad popover points to, in the coordinates of the navigation controller view.
    init(
        navigationController: UINavigationController,
        pages: [WMFShareReadingListDataController.Page],
        listName: String,
        sourceRect: CGRect
    ) {
        self.navigationController = navigationController
        self.pages = pages
        self.listName = listName
        self.sourceRect = sourceRect
    }

    deinit {
        shareTask?.cancel()
    }

    /// The link is on the wiki of the primary app language, like the Android app.
    @discardableResult
    func start() -> Bool {
        guard let linkProject = WMFDataEnvironment.current.primaryAppLanguage.map(WMFProject.wikipedia) ?? pages.first?.project else {
            return false
        }

        shareTask?.cancel()
        let sourceViewController = navigationController.topViewController
        shareTask = Task { [weak self, pages] in
            let result: Result<URL, Error>
            do {
                result = .success(try await WMFShareReadingListDataController().fetchShareURL(for: pages, linkProject: linkProject))
            } catch {
                DDLogError("Failed to create the share link of a reading list: \(error)")
                result = .failure(error)
            }
            guard !Task.isCancelled, let self, self.isShowing(sourceViewController) else { return }

            switch result {
            case .success(let shareURL):
                presentShareSheet(shareURL: shareURL)
            case .failure(let error):
                let message = (error as NSError).wmf_isNetworkConnectionError() ? CommonStrings.noInternetConnection : CommonStrings.genericErrorDescription
                WMFToastPresenter.shared.show(WMFToastConfig(title: message, duration: 5))
            }
        }
        return true
    }

    /// The reader can leave the screen before the link is ready. Then the share sheet and the error toast do not show.
    private func isShowing(_ sourceViewController: UIViewController?) -> Bool {
        sourceViewController != nil && navigationController.topViewController === sourceViewController
    }

    private func presentShareSheet(shareURL: URL) {
        let itemSource = ShareReadingListItemSource(message: Self.message(shareURL: shareURL), subject: listName)
        let activityViewController = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = navigationController.view
            activityViewController.popoverPresentationController?.sourceRect = sourceRect
        }
        navigationController.present(activityViewController, animated: true)
    }

    private static func message(shareURL: URL) -> String {
        let format = WMFLocalizedString(
            "reading-list-share-message",
            value: "Hi! I'd like to share my Wikipedia reading list with you: %1$@",
            comment: "Message sent to the recipient when the user shares a reading list. %1$@ is replaced with the link that imports the list."
        )
        return String.localizedStringWithFormat(format, shareURL.absoluteString)
    }
}

/// Gives the share sheet the message and the subject of a shared reading list. Mail uses the subject.
private final class ShareReadingListItemSource: NSObject, UIActivityItemSource {

    private let message: String
    private let subject: String

    init(message: String, subject: String) {
        self.message = message
        self.subject = subject
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        message
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        message
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        subject
    }
}
