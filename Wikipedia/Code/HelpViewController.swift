import MessageUI
import CocoaLumberjackSwift
import WMF

@objc(WMFHelpViewController)
class HelpViewController: SinglePageWebViewController {
    static let faqURLString = "https://m.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ"
    static let emailAddress = "mobile-ios-wikipedia@wikimedia.org"
    static let emailSubject = "Bug:"
    let dataStore: MWKDataStore
    
    @objc init?(dataStore: MWKDataStore, theme: Theme) {
        guard let faqURL = URL(string: HelpViewController.faqURLString) else {
            return nil
        }
        self.dataStore = dataStore
        super.init(url: faqURL, theme: theme)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(url: URL, theme: Theme) {
        fatalError("init(url:theme:) has not been implemented")
    }

    required init(url: URL, theme: Theme, doesUseSimpleNavigationBar: Bool = false) {
        fatalError("init(url:theme:doesUseSimpleNavigationBar:) has not been implemented")
    }

    lazy var sendEmailToolbarItem: UIBarButtonItem = {
        return UIBarButtonItem(title: WMFLocalizedString("button-report-a-bug", value: "Report a bug", comment: "Button text for reporting a bug"), style: .plain, target: self, action: #selector(sendEmail))
    }()
    
    lazy var exportUserDataToolbarItem: UIBarButtonItem = {
        return UIBarButtonItem(title: WMFLocalizedString("export-user-data", value: "Export User Data", comment: "Button for exporting user data"), style: .plain, target: self, action: #selector(exportUserData))
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        case unableToDetectContainerSize
        case unableToDetectLogSize
    }
    
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
    
    private func saveSyncedReadingListResultsToAppContainer(completion: @escaping () -> Void) {
        guard dataStore.authenticationManager.isLoggedIn else {
            completion()
            return
        }
        
        let readingListsController = self.dataStore.readingListsController
        let apiController = readingListsController.apiController
        let appSettingsShowSavedReadingList = readingListsController.isDefaultListEnabled
        let appSettingsSyncSavedArticlesAndLists = readingListsController.isSyncEnabled
        
        let dispatchQueue = DispatchQueue.global(qos: .userInitiated)
        dispatchQueue.async {

            let sharedCache = SharedContainerCache<UserDataExportSyncInfo>.init(pathComponent: .userDataExportSyncInfo, defaultCache: { UserDataExportSyncInfo(serverReadingLists: [], serverReadingListEntries: [], appSettingsSyncSavedArticlesAndLists: false, appSettingsShowSavedReadingList: false) })
            
            apiController.getAllReadingLists { (serverReadingLists, since, error) in
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
    
    @objc func exportUserData() {
        
        //set export button to spinner
        setupToolbarItems(isExportingUserData: true)

        saveSyncedReadingListResultsToAppContainer {
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
         
                FileManager.default.delegate = self
                
                let fileManager = FileManager.default
                let containerURL = fileManager.wmf_containerURL()
                let logFilePath = DDLog.wmf_currentLogFilePath()
                
                //Because we'll be copying the app container over to something that can be zipped up, we must check that we have at least enough free space for another container + log file
                var enoughSpace: Bool = true
                do {
                    if let self = self {
                        enoughSpace = try self.userHasEnoughSpace(containerURL: containerURL, logFilePath: logFilePath)
                    }
                } catch (let error) {
                    DDLogError("Error determining if there's enough free space: \(error)")
                }
                
                guard enoughSpace else {
                    DispatchQueue.main.async {
                        self?.wmf_showAlertWithMessage(WMFLocalizedString("export-user-data-space-error", value: "You do not have enough device space to export your user data. Please try again later.", comment: "Error message displayed after user has tried exporting their data and the system determines it doesn't have space to do so."))
                        self?.setupToolbarItems(isExportingUserData: false)
                    }
                    return
                }
                
                //First copy container URL into temporary temporary directory
                let temporaryAppContainerURL = fileManager.temporaryDirectory.appendingPathComponent(WMFApplicationGroupIdentifier)
                
                do {
                    try fileManager.copyItem(at: containerURL, to: temporaryAppContainerURL)
                } catch (let error) {
                    print(error)
                }
                
                let newLogURL = temporaryAppContainerURL.appendingPathComponent("console.log")
                
                //then copy log file into temporary container directory.
                if let logFilePath = DDLog.wmf_currentLogFilePath() {
                    do {
                        let logFileURL = URL(fileURLWithPath: logFilePath)
                        try fileManager.copyItem(at: logFileURL, to: newLogURL)
                    } catch (let error) {
                        DDLogError("Error moving log file to app container: \(error)")
                    }
                }
                
                //Then zip up app container
                
                //Inspired by https://recoursive.com/2021/02/25/create_zip_archive_using_only_foundation/
                //Thanks!
                
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
                        
                       
                    } catch (let error) {
                        DDLogError("Error moving zip file to temporary directory: \(error)")
                    }
                    
                }

                if let zipURL = zipURL,
                   error == nil {
                    DispatchQueue.main.async {
                        let avc = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
                        self?.present(avc, animated: true)
                        self?.setupToolbarItems(isExportingUserData: false)
                    }
                } else {
                    if let error = error {
                        DDLogError("Error zipping up app container: \(error)")
                    } else {
                        DDLogError("Error zipping up app container.")
                    }
                    
                    DispatchQueue.main.async {
                        self?.setupToolbarItems(isExportingUserData: false)
                    }
                }
                
                do {
                    try fileManager.removeItem(at: temporaryAppContainerURL)
                } catch (let error) {
                    DDLogError("Error deleting temp app container: \(error).")
                }
                
                fileManager.delegate = nil
            }
        }
    }
    
    @objc func sendEmail() {
        let address = HelpViewController.emailAddress
        let subject = HelpViewController.emailSubject
        let body = "\n\n\n\nVersion: \(WikipediaAppUtils.versionedUserAgent())"
        let mailto = "mailto:\(address)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        guard let encodedMailto = mailto, let mailtoURL = URL(string: encodedMailto), UIApplication.shared.canOpenURL(mailtoURL) else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(WMFLocalizedString("no-email-account-alert", value: "Please setup an email account on your device and try again.", comment: "Displayed to the user when they try to send a feedback email, but they have never set up an account on their device"), sticky: false, dismissPreviousAlerts: false)
            return
        }

        UIApplication.shared.open(mailtoURL)
    }

}

extension HelpViewController: FileManagerDelegate {
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAt srcURL: URL, to dstURL: URL) -> Bool {
        print(error)
        return true
    }
    
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAtPath srcPath: String, toPath dstPath: String) -> Bool {
        print(error)
        return true
    }
}
