import UIKit

class InTheNewsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let story: WMFFeedNewsStory
    let dataStore: MWKDataStore
    
    @IBOutlet weak var tableView: UITableView!
    
    required init(story: WMFFeedNewsStory, dataStore: MWKDataStore) {
        self.story = story
        self.dataStore = dataStore
        super.init(nibName: "InTheNewsViewController", bundle: nil)
        title = WMFLocalizedString("in-the-news-title", value:"In the news", comment:"Title for the 'In the news' notification & feed section")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("back", value:"Back", comment:"Generic 'Back' title for back button\n{{Identical|Back}}"), style: .plain, target:nil, action:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    
    @IBAction func close(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .wmf_articleListBackground
        tableView.separatorColor = .wmf_lightGray
        tableView.estimatedRowHeight = 64.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(WMFArticleListTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFArticleListTableViewCell.identifier())
        tableView.register(MultilineLabelTableViewCell.wmf_classNib(), forCellReuseIdentifier: MultilineLabelTableViewCell.identifier)
        tableView.register(FullSizeImageTableViewCell.wmf_classNib(), forCellReuseIdentifier: FullSizeImageTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    var mainArticlePreview: WMFFeedArticlePreview? {
        get {
            return story.featuredArticlePreview ?? story.articlePreviews?.first
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return mainArticlePreview?.thumbnailURL == nil ? 0 : 1
        case 1:
            return 1
        case 2:
            return story.articlePreviews?.count ?? 0
        default:
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let mainArticlePreview = mainArticlePreview else {
            return UITableViewCell()
        }
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FullSizeImageTableViewCell.identifier, for: indexPath) as? FullSizeImageTableViewCell else {
                return UITableViewCell()
            }
            
            cell.fullSizeImageView.wmf_showPlaceholder()
            guard let article = dataStore.fetchArticle(with: mainArticlePreview.articleURL), let imageURL = article.imageURL(forWidth: self.traitCollection.wmf_leadImageWidth) else {
                return cell
            }
            
            let detectFaces = UI_USER_INTERFACE_IDIOM() != .pad;
            cell.fullSizeImageView.wmf_setImage(with: imageURL, detectFaces: detectFaces, onGPU: true, failure: { (error) in cell.fullSizeImageView.wmf_showPlaceholder() }) {
            }
            
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MultilineLabelTableViewCell.identifier, for: indexPath) as? MultilineLabelTableViewCell else {
                return UITableViewCell()
            }
            
            guard let storyHTML = story.storyHTML else {
                return cell
            }
            
            var font: UIFont
            if #available(iOS 10.0, *) {
                font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body, compatibleWith: nil)
            } else {
                font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
            }
            let linkFont = UIFont.boldSystemFont(ofSize: font.pointSize)
            let attributedString = storyHTML.wmf_attributedStringByRemovingHTML(with: font, linkFont: linkFont)
            cell.multilineLabel.attributedText = attributedString
           
            return cell
        default:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFArticleListTableViewCell.identifier(), for: indexPath) as? WMFArticleListTableViewCell else {
                return UITableViewCell()
            }
            
            let index = indexPath.row
            guard let articlePreview = story.articlePreviews?[index] else {
                return UITableViewCell()
            }
            
            cell.setImageURL(articlePreview.thumbnailURL)
            
            cell.titleText = articlePreview.displayTitle
            if let wikidataDescription = articlePreview.wikidataDescription {
                cell.descriptionText = wikidataDescription.wmf_stringByCapitalizingFirstCharacter()
            }else{
                cell.descriptionText = articlePreview.snippet
            }
            
            return cell
        }
       
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 2
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        guard index >= 0 else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        guard let articlePreviews = story.articlePreviews, articlePreviews.count > index else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        let articlePreview = articlePreviews[index]
        let articleURL = articlePreview.articleURL
        
        wmf_pushArticle(with: articleURL, dataStore: dataStore, animated: true)
    }
}
