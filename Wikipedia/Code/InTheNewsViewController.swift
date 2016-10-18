import UIKit

class InTheNewsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let story: WMFFeedNewsStory
    
    @IBOutlet weak var storyLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    required init(story: WMFFeedNewsStory) {
        self.story = story
        super.init(nibName: "InTheNewsViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    
    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.alwaysBounceVertical = false
        tableView.alwaysBounceHorizontal = false
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.whiteColor()
        tableView.backgroundView = backgroundView
        tableView.registerNib(WMFArticleListTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFArticleListTableViewCell.identifier())
        tableView.dataSource = self
        tableView.delegate = self
        updateUIWithStory(story)
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
}
