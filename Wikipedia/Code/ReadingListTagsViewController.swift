import UIKit

class ReadingListTagsViewController: UIViewController {
    @IBOutlet weak var stackView: UIStackView!
    
    fileprivate let readingLists: [ReadingList]
    
    init(readingLists: [ReadingList]) {
        self.readingLists = readingLists
        super.init(nibName: "ReadingListTagsViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
