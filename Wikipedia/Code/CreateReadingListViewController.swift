import UIKit
import WMF

struct ImportedReadingList: Codable {
    let name: String?
    let description: String?
    let list: [String: [Int]]
}

enum ImportReadingListError: Error {
    case failureDecodingPayload
    case failureFetchingPageURLs
    case failureFetchingArticleObjects
    case missingDataStore
    case missingArticles
}

protocol CreateReadingListDelegate: NSObjectProtocol {
    func createReadingListViewController(_ createReadingListViewController: CreateReadingListViewController, didCreateReadingListWith name: String, description: String?, articles: [WMFArticle])
}

class CreateReadingListViewController: WMFScrollViewController, UITextFieldDelegate {
        
    @IBOutlet weak var readingListNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var readingListNameErrorLabel: UILabel!
    @IBOutlet weak var readingListNameTextField: ThemeableTextField!
    @IBOutlet weak var descriptionTextField: ThemeableTextField!
    
    @IBOutlet weak var createReadingListButton: WMFAuthButton!
    
    fileprivate var theme: Theme = Theme.standard
    fileprivate var articles: [WMFArticle]
    public let moveFromReadingList: ReadingList?
    
    weak var delegate: CreateReadingListDelegate?
    
    // Import shared reading list properties
    private let encodedPageIds: String?
    private var importedReadingList: ImportedReadingList?
    private let dataStore: MWKDataStore?
    private let pageIdsFetcher = PageIDToURLFetcher()
    
    var isInImportingMode: Bool {
        encodedPageIds != nil
    }
    
    lazy var importLoadingView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(importSpinner)
        view.backgroundColor = theme.colors.paperBackground
        NSLayoutConstraint.activate([
            importSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            importSpinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        view.isHidden = true
        return view
    }()

    lazy var importSpinner: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = theme.colors.primaryText
        return activityIndicator
    }()
    
    // MARK: Lifecycle
    
    init(theme: Theme, articles: [WMFArticle], moveFromReadingList: ReadingList? = nil, encodedPageIds: String? = nil, dataStore: MWKDataStore? = nil) {
        self.theme = theme
        self.articles = articles
        self.moveFromReadingList = moveFromReadingList
        self.encodedPageIds = encodedPageIds
        self.dataStore = dataStore
        super.init(nibName: "CreateReadingListViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
        readingListNameTextField.delegate = self
        descriptionTextField.delegate = self
        descriptionTextField.returnKeyType = .next
        readingListNameTextField.returnKeyType = .next
        readingListNameTextField.enablesReturnKeyAutomatically = true
        
        navigationItem.title = CommonStrings.createNewListTitle
        readingListNameLabel.text = WMFLocalizedString("reading-list-create-new-list-reading-list-name", value: "Reading list name", comment: "Title for label above text field for entering new list name.")
        descriptionLabel.text = WMFLocalizedString("reading-list-create-new-list-description", value: "Description", comment: "Title for label above text field for entering new list description.")
        readingListNameTextField.placeholder = WMFLocalizedString("reading-list-new-list-name-placeholder", value: "reading list title", comment: "Placeholder text appearing in text field for entering new list name")
        descriptionTextField.placeholder = WMFLocalizedString("reading-list-new-list-description-placeholder", value: "optional short description", comment: "Placeholder text appearing in text field for entering new list description")
        createReadingListButton.setTitle(WMFLocalizedString("reading-list-create-new-list-button-title", value: "Create reading list", comment: "Title for button allowing the user to create a new reading list."), for: .normal)
        
        createReadingListButton.isEnabled = false
        
        if isInImportingMode {
            setupForImportingReadingList()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isInImportingMode {
            readingListNameTextField.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(false)
    }
    
// MARK: Public
    
    func handleReadingListNameError(_ error: ReadingListError) {
        readingListNameTextField.textColor = theme.colors.error
        readingListNameErrorLabel.isHidden = false
        readingListNameErrorLabel.text = error.localizedDescription
        createReadingListButton.isEnabled = false
    }
    
// MARK: Actions
    
    @objc func closeButtonTapped(_ sender: UIButton) {
        
        if isInImportingMode {
            ReadingListsFunnel.shared.logCancelImport()
        }
        
        navigationController?.dismiss(animated: true)
    }
    
    @IBAction func createReadingListButtonPressed() {
        guard !isReadingListNameFieldEmpty, let trimmedName = readingListNameTextField.text?.trimmingCharacters(in: .whitespaces) else {
            return
        }
        let trimmedDescription = descriptionTextField.text?.trimmingCharacters(in: .whitespaces)
        delegate?.createReadingListViewController(self, didCreateReadingListWith: trimmedName, description: trimmedDescription, articles: articles)
    }
    
    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
        return true
    }

// MARK: Private
    
    private func setupForImportingReadingList() {
        
        guard isInImportingMode else {
            return
        }
        
        self.title = WMFLocalizedString("import-shared-reading-list-title", value: "Import shared reading list", comment: "Title of screen that imports a shared reading list.")
        let closeButton = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(closeButtonTapped(_:)))
        navigationItem.leftBarButtonItem = closeButton
        
        view.wmf_addSubviewWithConstraintsToEdges(importLoadingView)

        if let encodedPageIds = encodedPageIds {

            importSpinner.startAnimating()
            importLoadingView.isHidden = false

            articlesFromEncodedPageIds(encodedPageIds) { [weak self] result in

                guard let self = self else {
                    return
                }

                self.importSpinner.stopAnimating()
                self.importLoadingView.isHidden = true

                switch result {
                case .success(let articles):
                    self.articles = articles
                    self.readingListNameTextField.text = WMFLocalizedString("import-shared-reading-list-default-title", value: "My Reading List", comment: "Default title of a reading list imported through a shared link.")
                    self.createReadingListButton.isEnabled = !self.isReadingListNameFieldEmpty && self.readingListNameErrorLabel.isHidden
                case .failure(let error):
                    self.readingListNameTextField.isEnabled = false
                    self.descriptionTextField.isEnabled = false
                    self.createReadingListButton.isEnabled = false
                    WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                }
            }
        }
    }
    
    private func hideReadingListError() {
        guard !readingListNameErrorLabel.isHidden else {
            return
        }
        readingListNameErrorLabel.isHidden = true
        readingListNameTextField.textColor = theme.colors.primaryText
    }
    
    private var shouldEnableCreateReadingListButton: Bool {
        return (!isReadingListNameFieldEmpty && readingListNameTextField.isFirstResponder) && readingListNameErrorLabel.isHidden
    }
    
    // MARK: - UITextFieldDelegate
    
    fileprivate var isReadingListNameFieldEmpty: Bool {
        return !readingListNameTextField.wmf_hasNonWhitespaceText
    }
    
    fileprivate var isDescriptionFieldEmpty: Bool {
        return !descriptionTextField.wmf_hasNonWhitespaceText
    }
    
    @IBAction func textFieldDidChange(_ textField: UITextField) {
        if readingListNameTextField.isFirstResponder {
            hideReadingListError()
        }
        createReadingListButton.isEnabled = !isReadingListNameFieldEmpty && readingListNameErrorLabel.isHidden
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard !descriptionTextField.isFirstResponder else {
            readingListNameTextField.becomeFirstResponder()
            return true
        }
        if readingListNameTextField.isFirstResponder {
            descriptionTextField.becomeFirstResponder()
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if readingListNameTextField.isFirstResponder {
            hideReadingListError()
        }
        createReadingListButton.isEnabled = !isReadingListNameFieldEmpty && !readingListNameTextField.isFirstResponder && readingListNameErrorLabel.isHidden
        return true
    }
}

// MARK: Themeable

extension CreateReadingListViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link
        
        readingListNameTextField.apply(theme: theme)
        descriptionTextField.apply(theme: theme)
        
        readingListNameLabel.textColor = theme.colors.secondaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        readingListNameErrorLabel.textColor = theme.colors.error
        
        createReadingListButton.apply(theme: theme)
       
    }
}

// MARK: Importing Reading Lists

private extension CreateReadingListViewController {

    func articlesFromEncodedPageIds(_ encodedPageIds: String, completion: @escaping (Result<[WMFArticle], Error>) -> Void) {

        guard let importedReadingList = decodedReadingListFromEncodedPageIds(encodedPageIds) else {
            completion(.failure(ImportReadingListError.failureDecodingPayload))
            return
        }
        
        self.importedReadingList = importedReadingList
        
        var loggingArticleCount = 0
        for (_, value) in importedReadingList.list {
            loggingArticleCount = loggingArticleCount + value.count
        }
        
        ReadingListsFunnel.shared.logStartImport(articlesCount: loggingArticleCount)

        pageURLsFromImportedReadingList(importedReadingList) { [weak self] result in
            switch result {
            case .success(let urls):
                self?.articleObjectsFromArticleURLs(urls, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func decodedReadingListFromEncodedPageIds(_ encodedPageIds: String) -> ImportedReadingList? {
        guard let data = Data(base64Encoded: encodedPageIds),
              let result = try? JSONDecoder().decode(ImportedReadingList.self, from: data) else {
            return nil
        }
        
        return result
    }
    
    func pageURLsFromImportedReadingList(_ importedReadingList: ImportedReadingList, completion: @escaping ((Result<[URL], Error>) -> Void)) {
        
        // https://phabricator.wikimedia.org/T316822#8366987
        // Has the format:
        // {
        //     "en":[59874,31883,24868,14381],
        //     "ru":[59874,31883,24868,14381]
        // }
        let listDict = importedReadingList.list

        // Turn into format:
        // {
        //     https://en.wikipedia.org: [59874,31883,24868,14381],
        //     https://ru.wikipedia.org: [59874,31883,24868,14381]
        // }
        var siteURLDict: [URL: [Int]] = [:]
        for (key, value) in listDict {
            if let siteURL = NSURL.wmf_URL(withDefaultSiteAndLanguageCode: key) {
                siteURLDict[siteURL] = value
            }
        }

        // Fetch page URLs for each site, combine into single array of page URLs
        let group = DispatchGroup()
        var finalPageURLs: [URL] = []
        var errors: [Error] = []
        for (key, value) in siteURLDict {
            group.enter()
            pageIdsFetcher.fetchPageURLs(key, pageIDs: value) { error in
                DispatchQueue.main.async {
                    errors.append(error)
                    group.leave()
                }
            } success: { urls in
                DispatchQueue.main.async {
                    finalPageURLs.append(contentsOf: urls)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {

            if let error = errors.first {
                completion(.failure(error))
                return
            }

            guard !finalPageURLs.isEmpty else {
                completion(.failure(ImportReadingListError.failureFetchingPageURLs))
                return
            }

            completion(.success(finalPageURLs))
        }
    }

    func articleObjectsFromArticleURLs(_ articleURLs: [URL], completion: @escaping ((Result<[WMFArticle], Error>) -> Void)) {
        
        guard let dataStore = dataStore else {
            completion(.failure(ImportReadingListError.missingDataStore))
            return
        }

        let keys = articleURLs.compactMap { $0.wmf_inMemoryKey }

        let articleFetcher = ArticleFetcher()
        articleFetcher.fetchArticleSummaryResponsesForArticles(withKeys: keys) { result in

            DispatchQueue.main.async {
                var articles: [WMFArticle] = []
                do {
                    let articleSummaries = try dataStore.viewContext.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: result)

                    for (_, value) in articleSummaries {
                        articles.append(value)
                    }

                    guard !articles.isEmpty else {
                        completion(.failure(ImportReadingListError.failureFetchingArticleObjects))
                        return
                    }

                    completion(.success(articles))
                } catch let error {
                    completion(.failure(error))
                }
            }
        }
    }
}
