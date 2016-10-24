import UIKit

class InTheNewsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let story: WMFFeedNewsStory
    let dataStore: MWKDataStore
    let previewStore: WMFArticlePreviewDataStore
    
    @IBOutlet weak var storyLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
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
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRectZero)
        updateUIWithStory(story)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: animated)
        }
    }
    
    func updateUIWithStory(story: WMFFeedNewsStory) {
        tableView.reloadData()
        
        guard let mainArticlePreview = story.mostPopularArticlePreview ?? story.articlePreviews?.first else {
            return
        }
        
        if let thumbnailURL = mainArticlePreview.thumbnailURL {
            imageView.wmf_setImageWithURL(thumbnailURL, detectFaces: true, onGPU: true, failure: { (error) in }) { }
        } else {
            imageView.image = nil
        }
        
        guard let storyHTML = story.storyHTML else {
            return
        }
        
        var font: UIFont
        if #available(iOS 10.0, *) {
            font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody, compatibleWithTraitCollection: nil)
        } else {
            font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        }
        let linkFont = UIFont.boldSystemFontOfSize(font.pointSize)
        let attributedString = storyHTML.wmf_attributedStringByRemovingHTMLWithFont(font, linkFont: linkFont)
        storyLabel.attributedText = attributedString
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return story.articlePreviews?.count ?? 0
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(WMFArticleListTableViewCell.identifier(), forIndexPath: indexPath) as? WMFArticleListTableViewCell else {
            return UITableViewCell()
        }
        
        guard let articlePreview = story.articlePreviews?[indexPath.row] else {
            return UITableViewCell()
        }
        
        cell.setImageURL(articlePreview.thumbnailURL)
        
        cell.titleText = articlePreview.displayTitle
        cell.descriptionText = articlePreview.snippet
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let articlePreviews = story.articlePreviews where articlePreviews.count > indexPath.row else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }
        
        let articlePreview = articlePreviews[indexPath.row]
        let articleURL = articlePreview.articleURL
        
        wmf_pushArticleWithURL(articleURL, dataStore: dataStore, previewStore: previewStore, animated: true)
    }
}
