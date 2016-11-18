import UIKit

class InTheNewsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let story: WMFFeedNewsStory
    let dataStore: MWKDataStore
    let previewStore: WMFArticlePreviewDataStore
    
    @IBOutlet weak var tableView: UITableView!
    
    required init(story: WMFFeedNewsStory, dataStore: MWKDataStore, previewStore: WMFArticlePreviewDataStore) {
        self.story = story
        self.dataStore = dataStore
        self.previewStore = previewStore
        super.init(nibName: "InTheNewsViewController", bundle: nil)
        title = localizedStringForKeyFallingBackOnEnglish("in-the-news-title")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: localizedStringForKeyFallingBackOnEnglish("back"), style: .Plain, target:nil, action:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    
    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.wmf_articleListBackgroundColor()
        tableView.separatorColor = UIColor.wmf_lightGrayColor()
        tableView.estimatedRowHeight = 64.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.registerNib(WMFArticleListTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFArticleListTableViewCell.identifier())
        tableView.registerNib(MultilineLabelTableViewCell.wmf_classNib(), forCellReuseIdentifier: MultilineLabelTableViewCell.identifier)
        tableView.registerNib(FullSizeImageTableViewCell.wmf_classNib(), forCellReuseIdentifier: FullSizeImageTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: animated)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = story.articlePreviews?.count else {
            return 2
        }
        return count + 2
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let mainArticlePreview = story.featuredArticlePreview ?? story.articlePreviews?.first else {
            return UITableViewCell()
        }
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCellWithIdentifier(FullSizeImageTableViewCell.identifier, forIndexPath: indexPath) as? FullSizeImageTableViewCell else {
                return UITableViewCell()
            }
            
            guard let thumbnailURL = mainArticlePreview.thumbnailURL  else {
                cell.fullSizeImageView.image = nil
                return cell
            }
            
            cell.fullSizeImageView.wmf_setImageWithURL(thumbnailURL, detectFaces: true, onGPU: true, failure: { (error) in }) {}
            
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCellWithIdentifier(MultilineLabelTableViewCell.identifier, forIndexPath: indexPath) as? MultilineLabelTableViewCell else {
                return UITableViewCell()
            }
            
            guard let storyHTML = story.storyHTML else {
                return cell
            }
            
            var font: UIFont
            if #available(iOS 10.0, *) {
                font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody, compatibleWithTraitCollection: nil)
            } else {
                font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            }
            let linkFont = UIFont.boldSystemFontOfSize(font.pointSize)
            let attributedString = storyHTML.wmf_attributedStringByRemovingHTMLWithFont(font, linkFont: linkFont)
            cell.multilineLabel.attributedText = attributedString
           
            return cell
        default:
            guard let cell = tableView.dequeueReusableCellWithIdentifier(WMFArticleListTableViewCell.identifier(), forIndexPath: indexPath) as? WMFArticleListTableViewCell else {
                return UITableViewCell()
            }
            
            let index = indexPath.row - 2
            guard let articlePreview = story.articlePreviews?[index] else {
                return UITableViewCell()
            }
            
            cell.setImageURL(articlePreview.thumbnailURL)
            
            cell.titleText = articlePreview.displayTitle
            cell.descriptionText = articlePreview.snippet
            
            return cell
        }
       
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row > 1
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let index = indexPath.row - 2
        guard index >= 0 else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }
        guard let articlePreviews = story.articlePreviews where articlePreviews.count > index else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }
        
        let articlePreview = articlePreviews[index]
        let articleURL = articlePreview.articleURL
        
        wmf_pushArticleWithURL(articleURL, dataStore: dataStore, previewStore: previewStore, animated: true)
    }
}
