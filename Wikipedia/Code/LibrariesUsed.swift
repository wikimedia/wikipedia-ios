
public struct LibraryUsed {
    let title:String
    let licenseName:String
    let licenseText:String
}

class LibrariesUsedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var libraries:[LibraryUsed] = []
    @IBOutlet weak var tableView: UITableView!
    
    public static let storyboardName = "LibrariesUsed"
    
    private static let cellReuseIdentifier = "org.wikimedia.libraries.used.cell"
    private static let dataFileName = "LibrariesUsed.plist"
    
    private static let plistLibrariesUsedKey = "LibrariesUsed"
    private static let plistTitleKey = "Title"
    private static let plistLicenseNameKey = "LicenseName"
    private static let plistLicenseTextKey = "LicenseText"

    func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
    }
    
    lazy private var tableHeaderView: UIView! = {
        let headerFrame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 56)
        let headerView = UIView.init(frame: headerFrame)
        let labelFrame = headerView.frame.insetBy(dx: 10, dy: 10)
        let label = UILabel.init(frame: labelFrame)
        if #available(iOS 10.0, *) {
            label.adjustsFontForContentSizeCategory = true
        }
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .wmf_darkGray
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
        
        view.backgroundColor = .wmf_lightGray
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: LibrariesUsedViewController.cellReuseIdentifier)
        tableView.estimatedRowHeight = 41
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableHeaderView = tableHeaderView
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
            let librariesUsedDataArray = dict[LibrariesUsedViewController.plistLibrariesUsedKey] as? Array<Dictionary<String, Any>>
        else {
            assertionFailure("\n\nUnexpected items found in '\(plistPath)' or its '\(LibrariesUsedViewController.plistLibrariesUsedKey)' array.\n\n")
            return []
        }
        return librariesUsedDataArray
            .flatMap {library -> LibraryUsed? in
                guard
                    let title = library[LibrariesUsedViewController.plistTitleKey] as? String,
                    let licenseName = library[LibrariesUsedViewController.plistLicenseNameKey] as? String,
                    let licenseText = library[LibrariesUsedViewController.plistLicenseTextKey] as? String
                else {
                    assertionFailure("\n\nOne of the following required keys not found in '\(LibrariesUsedViewController.plistLibrariesUsedKey)' array in '\(LibrariesUsedViewController.dataFileName)': '\(LibrariesUsedViewController.plistTitleKey)', '\(LibrariesUsedViewController.plistLicenseNameKey)', '\(LibrariesUsedViewController.plistLicenseTextKey)'\n\n")
                    return nil
                }
                return LibraryUsed.init(title: title.wmf_stringByCapitalizingFirstCharacter(), licenseName: licenseName, licenseText: licenseText)
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
        let library:LibraryUsed = self.libraries[indexPath.row];
        cell.textLabel?.text = library.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let libraryVC = LibraryUsedViewController.wmf_viewControllerFromStoryboardNamed(LibrariesUsedViewController.storyboardName)
        let library = self.libraries[indexPath.row];
        libraryVC.library = library
        libraryVC.title = library.title
        navigationController?.pushViewController(libraryVC, animated: true)
    }
}

class LibraryUsedViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    public var library: LibraryUsed?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textContainerInset = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        guard let licenseText = library?.licenseText else { return }
        textView.text = clean(licenseString: licenseText)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textView.setContentOffset(.zero, animated: false)
    }
    
    // Minimal cleanups on license copy.
    //  - consecutive line breaks reduce to 2 line breaks
    //  - non-consecutive line breaks converted to spaces
    private func clean(licenseString: String) -> String {
        var string = licenseString
        let breaksPlaceholder = "#breaks_placeholder#"
        let regex1 = try! NSRegularExpression(pattern: "\n\\s*\n", options:.caseInsensitive)
        string = regex1.stringByReplacingMatches(in: string, options: [], range: NSRange(location: 0, length: string.characters.count), withTemplate: breaksPlaceholder)
        string = string.replacingOccurrences(of: "\n", with: " ")
        let regex2 = try! NSRegularExpression(pattern: "\\s+", options:.caseInsensitive)
        string = regex2.stringByReplacingMatches(in: string, options: [], range: NSRange(location: 0, length: string.characters.count), withTemplate: " ")
        string = string.replacingOccurrences(of: breaksPlaceholder, with: "\n\n")
        return string
    }
}
