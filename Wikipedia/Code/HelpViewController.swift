import MessageUI
import CocoaLumberjackSwift
import WMF
import WMFComponents

@objc(WMFHelpViewController)
class HelpViewController: SinglePageWebViewController {
    static let faqURLString = "https://m.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ"
    static let emailAddress = "ios-support@wikimedia.org"
    static let emailSubject = "Bug:"
    let dataStore: MWKDataStore
    
    @objc init?(dataStore: MWKDataStore, theme: Theme) {
        guard let faqURL = URL(string: HelpViewController.faqURLString) else {
            return nil
        }
        self.dataStore = dataStore
        let config = SinglePageWebViewController.StandardConfig(url: faqURL, useSimpleNavigationBar: false)
        super.init(configType: .standard(config), theme: theme)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(configType: ConfigType, theme: Theme) {
        fatalError("init(configType:theme:) has not been implemented")
    }
    
    lazy var sendEmailToolbarItem: UIBarButtonItem = {
        return UIBarButtonItem(title: WMFLocalizedString("button-report-a-bug", value: "Report a bug", comment: "Button text for reporting a bug"), style: .plain, target: self, action: #selector(sendEmail))
    }()
    
    lazy var exportUserDataToolbarItem: UIBarButtonItem = {
        return UIBarButtonItem(title: WMFLocalizedString("export-user-data-title", value: "Export User Data", comment: "Button title for exporting user data"), style: .plain, target: self, action: #selector(exportUserData))
    }()
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.color = theme.colors.primaryText
        return activityIndicator
    }()
    
    lazy var spinnerToolbarItem: UIBarButtonItem = {
        return UIBarButtonItem(customView: activityIndicator)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = nil
        setupToolbar()
    }
    
    private func setupToolbarItems(isExportingUserData: Bool) {
        
        let exportItem = isExportingUserData ? spinnerToolbarItem : exportUserDataToolbarItem
        if isExportingUserData {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        
        let leadingSpace: CGFloat = isExportingUserData ? 30 : 8
        
        self.toolbar.items = [UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: leadingSpace), exportItem, UIBarButtonItem.flexibleSpaceToolbar(), sendEmailToolbarItem, UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: 8)]
    }

    private func setupToolbar() {
        enableToolbar()
        setupToolbarItems(isExportingUserData: false)
        setToolbarHidden(false, animated: false)
    }
    
    enum UserDataExportError: Error {
        case unableToDetectSystemFreeSpace
        case unableToDetectLogSize
    }
    
    @objc func exportUserData() {
        
        let confirmationTitle = WMFLocalizedString("export-user-data-confirmation-title", value: "Share app library?", comment: "Title of confirmation modal after user taps \"Export User Data\" button.")
        let confirmationMessage = WMFLocalizedString("export-user-data-confirmation-message", value: "Sharing your app library includes data about your Reading lists and history, preferences, and Explore feed content. This data file should only be shared with a trusted recipient to use for technical diagnostic purposes.", comment: "Message of confirmation modal after user taps \"Export User Data\" button.")
        let shareAction = UIAlertAction(title: CommonStrings.shareActionTitle, style: .default) { _ in
            self.kickoffExportUserDataProcess()
        }
        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)
        wmf_showAlert(title: confirmationTitle, message: confirmationMessage, actions: [shareAction, cancelAction])
    }
    
    @objc func sendEmail() {
        let address = HelpViewController.emailAddress
        let subject = HelpViewController.emailSubject
        let body = "\n\n\n\nVersion: \(WikipediaAppUtils.versionedUserAgent())"
        let mailto = "mailto:\(address)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        guard let encodedMailto = mailto, let mailtoURL = URL(string: encodedMailto), UIApplication.shared.canOpenURL(mailtoURL) else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(CommonStrings.noEmailClient, sticky: false, dismissPreviousAlerts: false)
            return
        }

        UIApplication.shared.open(mailtoURL)
    }

}

extension HelpViewController: FileManagerDelegate {
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAt srcURL: URL, to dstURL: URL) -> Bool {
        return true
    }
    
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAtPath srcPath: String, toPath dstPath: String) -> Bool {
        return true
    }
}

// MARK: Exporting User Data Helpers

private extension HelpViewController {
    func userHasEnoughSpace(containerURL: URL, logFilePath: String?) throws -> Bool {
        
        let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
        
        guard let systemFreeSpace = systemAttributes[.systemFreeSize] as? Int64 else {
            throw UserDataExportError.unableToDetectSystemFreeSpace
        }
        
        var logSize: Int64 = 0
        if let logFilePath = logFilePath {
            let logAttributes = try FileManager.default.attributesOfItem(atPath: logFilePath)
            guard let unwrappedLogSize = logAttributes[.size] as? Int64 else {
                throw UserDataExportError.unableToDetectLogSize
            }
            
            logSize = unwrappedLogSize
        }
        
        let containerSize = FileManager.default.sizeOfDirectory(at: containerURL)
        
        return systemFreeSpace > containerSize + logSize
    }
    
    func saveSyncedReadingListResultsToAppContainer(completion: @escaping () -> Void) {
        guard dataStore.authenticationManager.authStateIsPermanent else {
            completion()
            return
        }
        
        let readingListsController = self.dataStore.readingListsController
        let apiController = readingListsController.apiController
        let appSettingsShowSavedReadingList = readingListsController.isDefaultListEnabled
        let appSettingsSyncSavedArticlesAndLists = readingListsController.isSyncEnabled
        
        let dispatchQueue = DispatchQueue.global(qos: .userInitiated)
        dispatchQueue.async {

            let sharedCache = SharedContainerCache.init(fileName: "User Data Export Sync Info")
            
            apiController.getAllReadingLists { (serverReadingLists, _, _) in
                dispatchQueue.async {
                    let group = DispatchGroup()
                    
                    var serverReadingListEntries: [APIReadingListEntry] = []
                    
                    for remoteReadingList in serverReadingLists {
                        group.enter()
                        apiController.getAllEntriesForReadingListWithID(readingListID: remoteReadingList.id, completion: { (entries, error) in
                            dispatchQueue.async {
                                serverReadingListEntries.append(contentsOf: entries)
                                group.leave()
                            }
                        })
                    }
                    
                    group.notify(queue: dispatchQueue) {
                        let userDataExportSyncInfo = UserDataExportSyncInfo(serverReadingLists: serverReadingLists, serverReadingListEntries: serverReadingListEntries, appSettingsSyncSavedArticlesAndLists: appSettingsSyncSavedArticlesAndLists, appSettingsShowSavedReadingList: appSettingsShowSavedReadingList)
                        sharedCache.saveCache(userDataExportSyncInfo)
                        completion()
                    }
                }
            }
        }
    }
    
    func copyLogFile(temporaryAppContainerURL: URL, fileManager: FileManager) {
        let newLogURL = temporaryAppContainerURL.appendingPathComponent("console.log")
        
        if let logFilePath = DDLog.wmf_currentLogFilePath() {
            do {
                let logFileURL = URL(fileURLWithPath: logFilePath)
                try fileManager.copyItem(at: logFileURL, to: newLogURL)
            } catch let error {
                DDLogError("Error moving log file to app container: \(error)")
            }
        }
    }
    
    func removeUnnecessaryFilesAndSubdirectories(temporaryAppContainerURL: URL, fileManager: FileManager) {
        var urlsToRemove: [URL] = []
        urlsToRemove.append(temporaryAppContainerURL.appendingPathComponent("Event Logging"))
        urlsToRemove.append(temporaryAppContainerURL.appendingPathComponent("Event Platform"))
        urlsToRemove.append(temporaryAppContainerURL.appendingPathComponent("Library"))
        urlsToRemove.append(temporaryAppContainerURL.appendingPathComponent(SharedContainerCacheCommonNames.pushNotificationsCache).appendingPathExtension("json"))
        urlsToRemove.append(temporaryAppContainerURL.appendingPathComponent("RemoteNotifications").appendingPathExtension("sqlite"))
        urlsToRemove.append(temporaryAppContainerURL.appendingPathComponent("RemoteNotifications").appendingPathExtension("sqlite-shm"))
        urlsToRemove.append(temporaryAppContainerURL.appendingPathComponent("RemoteNotifications").appendingPathExtension("sqlite-wal"))
        urlsToRemove.append(temporaryAppContainerURL.appendingPathComponent(SharedContainerCacheCommonNames.widgetCache).appendingPathExtension("json"))
        for url in urlsToRemove {
            do {
                try fileManager.removeItem(at: url)
            } catch let error {
                DDLogError("Error deleting unnecessary files from app container: \(error)")
            }
        }
    }
    
    func zipUpAndShare(temporaryAppContainerURL: URL, fileManager: FileManager) {

        // Inspired by https://recoursive.com/2021/02/25/create_zip_archive_using_only_foundation/
        var zipURL: URL?
        var error: NSError?
        
        let coordinator = NSFileCoordinator()

        coordinator.coordinate(readingItemAt: temporaryAppContainerURL, options: [.forUploading], error: &error) { (url) in
            
            do {
                zipURL = try fileManager.url(
                    for: .itemReplacementDirectory,
                    in: .userDomainMask,
                    appropriateFor: url,
                    create: true
                ).appendingPathComponent("app-container.zip")
                
                if let zipURL = zipURL {
                    try fileManager.moveItem(at: url, to: zipURL)
                }
                
               
            } catch let error {
                DDLogError("Error moving zip file to temporary directory: \(error)")
                DispatchQueue.main.async {
                    self.handleGenericUserExportError()
                }
                return
            }
            
        }

        if let zipURL = zipURL,
           error == nil {
            DispatchQueue.main.async {
                self.setupToolbarItems(isExportingUserData: false)
                let avc = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
                avc.popoverPresentationController?.barButtonItem = self.exportUserDataToolbarItem
                self.present(avc, animated: true)
            }
        } else {
            if let error = error {
                DDLogError("Error zipping up app container: \(error)")
            } else {
                DDLogError("Error zipping up app container.")
            }
            
            DispatchQueue.main.async {
                self.handleGenericUserExportError()
            }
        }
        
        do {
            try fileManager.removeItem(at: temporaryAppContainerURL)
        } catch let error {
            DDLogError("Error deleting temp app container: \(error).")
        }
        
        fileManager.delegate = nil
    }
    
    private func handleGenericUserExportError() {
        self.wmf_showAlertWithMessage(WMFLocalizedString("export-user-data-generic-error", value: "There was an error while exporting your data. Please try again later.", comment: "Error message displayed after user has tried exporting their data and an error occurs."))
        self.setupToolbarItems(isExportingUserData: false)
    }
    
    func kickoffExportUserDataProcess() {
        // Set export button to spinner
        setupToolbarItems(isExportingUserData: true)

        saveSyncedReadingListResultsToAppContainer(completion: {
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                
                guard let self = self else {
                    return
                }
         
                FileManager.default.delegate = self
                
                let fileManager = FileManager.default
                let containerURL = fileManager.wmf_containerURL()
                let logFilePath = DDLog.wmf_currentLogFilePath()
                
                // Because we'll be copying the app container over to something that can be zipped up, we must check that we have at least enough free space for another container + log file
                var enoughSpace: Bool = false
                do {
                    enoughSpace = try self.userHasEnoughSpace(containerURL: containerURL, logFilePath: logFilePath)
                } catch {
                    DDLogError("Error determining if there's enough free space: \(error)")
                    DispatchQueue.main.async {
                        self.handleGenericUserExportError()
                    }
                    return
                }
                
                guard enoughSpace else {
                    DispatchQueue.main.async {
                        self.wmf_showAlertWithMessage(WMFLocalizedString("export-user-data-space-error", value: "You do not have enough device space to export your user data. Please try again later.", comment: "Error message displayed after user has tried exporting their data and the system determines it doesn't have space to do so."))
                        self.setupToolbarItems(isExportingUserData: false)
                    }
                    return
                }
                
                // First copy container into temporary directory
                let temporaryAppContainerURL = fileManager.temporaryDirectory.appendingPathComponent(WMFApplicationGroupIdentifier)
                
                do {
                    try fileManager.copyItem(at: containerURL, to: temporaryAppContainerURL)
                } catch let error {
                    DDLogError("Error copying container into temporary directory: \(error)")
                    DispatchQueue.main.async {
                        self.handleGenericUserExportError()
                    }
                    return
                }
                
                // Add log file, prune, zip and export temporary app container directory
                self.copyLogFile(temporaryAppContainerURL: temporaryAppContainerURL, fileManager: fileManager)
                self.removeUnnecessaryFilesAndSubdirectories(temporaryAppContainerURL: temporaryAppContainerURL, fileManager: fileManager)
                self.zipUpAndShare(temporaryAppContainerURL: temporaryAppContainerURL, fileManager: fileManager)
            }
        })
    }
}
