import WMFComponents
import WMF

public struct LibraryUsed {
    let title:String
    let licenseName:String
    let licenseText:String
}

class LibrariesUsedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var libraries:[LibraryUsed] = []
    @IBOutlet weak var tableView: UITableView!
    
    @objc public static let storyboardName = "LibrariesUsed"
    
    private static let cellReuseIdentifier = "org.wikimedia.libraries.used.cell"
    private static let dataFileName = "LibrariesUsed.plist"
    
    private static let plistLibrariesUsedKey = "LibrariesUsed"
    private static let plistTitleKey = "Title"
    private static let plistLicenseNameKey = "LicenseName"
    private static let plistLicenseTextKey = "LicenseText"
    
    fileprivate var theme = Theme.standard

    @objc func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
        navigationItem.leftBarButtonItem?.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
    }
    
    lazy private var tableHeaderView: UIView = {
        let headerFrame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 56)
        let headerView = UIView.init(frame: headerFrame)
        let labelFrame = headerView.frame.insetBy(dx: 10, dy: 10)
        let label = UILabel.init(frame: labelFrame)
        label.adjustsFontForContentSizeCategory = true
        label.font = WMFFont.for(.footnote)
        label.textColor = self.theme.colors.primaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = String.localizedStringWithFormat(WMFLocalizedString("about-libraries-licenses-title", value:"We love open source software %1$@", comment:"Title for list of library licenses. %1$@ will be replaced with an emoji expressing our love for open source software"), "💖")
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        headerView.addSubview(label)
        return headerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.apply(theme: self.theme)
        view.backgroundColor = WMFColor.gray400
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: LibrariesUsedViewController.cellReuseIdentifier)
        tableView.estimatedRowHeight = 41
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableHeaderView = tableHeaderView
        tableView.semanticContentAttribute = .forceLeftToRight
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target:nil, action:nil)
        
        title = WMFLocalizedString("about-libraries", value:"Libraries used", comment:"Header text for libraries section (as in a collection of subprograms used to develop software) of the about page. Is not capitalised for aesthetic reasons, but could be capitalised in translations.")
        
        let fileName = LibrariesUsedViewController.dataFileName
        guard
            let plistPath = Bundle.main.path(forResource: fileName.wmf_substring(before: "."), ofType: fileName.wmf_substring(after: "."))
        else {
            assertionFailure("Could find '\(fileName)' resource.")
            return
        }
        libraries = librariesUsed(from: plistPath)
    }
    
    private func librariesUsed(from plistPath: String) -> [LibraryUsed] {
        guard
            let dict = NSDictionary(contentsOfFile: plistPath) as? [String: Any],
            let librariesUsedDataArray = dict[LibrariesUsedViewController.plistLibrariesUsedKey] as? [[String: Any]]
        else {
            assertionFailure("\n\nUnexpected items found in '\(plistPath)' or its '\(LibrariesUsedViewController.plistLibrariesUsedKey)' array.\n\n")
            return []
        }
        return librariesUsedDataArray
            .compactMap {library -> LibraryUsed? in
                guard
                    let title = library[LibrariesUsedViewController.plistTitleKey] as? String,
                    let licenseName = library[LibrariesUsedViewController.plistLicenseNameKey] as? String,
                    let licenseText = library[LibrariesUsedViewController.plistLicenseTextKey] as? String
                else {
                    assertionFailure("\n\nOne of the following required keys not found in '\(LibrariesUsedViewController.plistLibrariesUsedKey)' array in '\(LibrariesUsedViewController.dataFileName)': '\(LibrariesUsedViewController.plistTitleKey)', '\(LibrariesUsedViewController.plistLicenseNameKey)', '\(LibrariesUsedViewController.plistLicenseTextKey)'\n\n")
                    return nil
                }
                return LibraryUsed.init(title: title.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguageCode: "en"), licenseName: licenseName, licenseText: licenseText)
            }
            .sorted(by: {
                $0.title < $1.title
            })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return libraries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LibrariesUsedViewController.cellReuseIdentifier, for: indexPath)
        cell.contentView.semanticContentAttribute = .forceLeftToRight
        cell.textLabel?.semanticContentAttribute = .forceLeftToRight
        cell.textLabel?.textAlignment = .left
        
        cell.backgroundColor = theme.colors.paperBackground
        cell.textLabel?.textColor = theme.colors.primaryText
        
        cell.selectionStyle = .default
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = theme.colors.midBackground
        
        let library:LibraryUsed = self.libraries[indexPath.row]
        cell.textLabel?.text = library.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let libraryVC = LibraryUsedViewController.wmf_viewControllerFromStoryboardNamed(LibrariesUsedViewController.storyboardName)
        libraryVC.apply(theme: self.theme)
        let library = self.libraries[indexPath.row]
        libraryVC.library = library
        libraryVC.title = library.title
        navigationController?.pushViewController(libraryVC, animated: true)
    }
}

class LibraryUsedViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    public var library: LibraryUsed?
    
    fileprivate var theme = Theme.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.apply(theme: self.theme)
        
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        guard let licenseText = library?.licenseText else { return }
        textView.text = normalizeWhitespaceForBetterReadability(from: licenseText)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textView.setContentOffset(.zero, animated: false)
    }
    
    private var newlineOptionalWhitespaceNewlineRegex: NSRegularExpression? = {
        do {
            return try NSRegularExpression(pattern: "\\R\\s*\\R", options: [])
        } catch {
            assertionFailure("regex failed to compile")
        }
        return nil
    }()

    private var oneOrMoreWhitespaceCharactersRegex: NSRegularExpression? = {
        do {
            return try NSRegularExpression(pattern: "\\s+", options: [])
        } catch {
            assertionFailure("regex failed to compile")
        }
        return nil
    }()
    
    // Minimal cleanups on license text.
    //  - consecutive line breaks reduce to 2 line breaks
    //  - non-consecutive line breaks converted to spaces (similar to HTML)
    // Imperfect but *vast* improvement in readability especially with line wrapping.
    private func normalizeWhitespaceForBetterReadability(from licenseString: String) -> String {
        guard
            let multiNewlineRegex = newlineOptionalWhitespaceNewlineRegex,
            let whitespaceRegex = oneOrMoreWhitespaceCharactersRegex
        else {
            assertionFailure("regex(s) failed to compile")
            return licenseString
        }
        var string = licenseString
        let placeholder = "#temporary_placeholder#"
        string = multiNewlineRegex.stringByReplacingMatches(in: string, options: [], range: string.fullRange, withTemplate: placeholder)
        string = string.components(separatedBy: .newlines).joined(separator: " ")
        string = whitespaceRegex.stringByReplacingMatches(in: string, options: [], range: string.fullRange, withTemplate: " ")
        string = string.replacingOccurrences(of: placeholder, with: "\n\n")
        return string
    }
}

extension LibrariesUsedViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        tableView.backgroundColor = theme.colors.baseBackground
        tableView.separatorColor = theme.colors.chromeBackground
        tableView.reloadData()
    }
}

extension LibraryUsedViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        self.view.backgroundColor = theme.colors.baseBackground
        self.textView.backgroundColor = theme.colors.baseBackground
        self.textView.textColor = theme.colors.primaryText
    }
}
