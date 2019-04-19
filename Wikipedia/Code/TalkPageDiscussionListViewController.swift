
import UIKit

protocol TalkPageDiscussionListDelegate: class {
    func tappedDiscussion(viewController: TalkPageDiscussionListViewController)
}

class TalkPageDiscussionListViewController: ColumnarCollectionViewController {
    
    weak var delegate: TalkPageDiscussionListDelegate?
    var dataStore: MWKDataStore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        layoutManager.register(DiscussionListItemCollectionViewCell.self, forCellWithReuseIdentifier: "TalkPageDiscussionCell", addPlaceholder: true)
        collectionView.delegate = self
        collectionView.reloadData()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TalkPageDiscussionCell", for: indexPath)
        cell.backgroundColor = .green
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        let estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        return estimate
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.tappedDiscussion(viewController: self)
    }

}
