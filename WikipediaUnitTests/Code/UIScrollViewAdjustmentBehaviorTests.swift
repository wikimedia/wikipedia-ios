import XCTest

class WMFAdjustmentBehaviorTestScrollView: UIScrollView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        if #available(iOS 11, *) {
            self.contentInsetAdjustmentBehavior = .scrollableAxes
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UIScrollViewAdjustmentBehaviorTest: XCTestCase {
    func testInheritanceOfScrollView() {
        if #available(iOS 11, *) {
            let scrollView = WMFAdjustmentBehaviorTestScrollView()
            XCTAssertEqual(scrollView.contentInsetAdjustmentBehavior, .scrollableAxes)
        }
    }
    
    func testInitialValueOfAdjustmentBehavior() {
        if #available(iOS 11, *) {
            let scrollView = UIScrollView()
            XCTAssertEqual(scrollView.contentInsetAdjustmentBehavior, .never)
        }
    }
    
    func testChangedValueOfAdjustmentBehavior() {
        if #available(iOS 11, *) {
            let scrollView = UIScrollView()
            scrollView.contentInsetAdjustmentBehavior = .automatic
            XCTAssertEqual(scrollView.contentInsetAdjustmentBehavior, .automatic)
        }
    }
    
    func testInitialValueByCollectionView() {
        if #available(iOS 11, *) {
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
            XCTAssertEqual(collectionView.contentInsetAdjustmentBehavior, .never)
        }
    }
    
    func testInitialValueOfAdjustmentBehaviorByTableView() {
        if #available(iOS 11, *) {
            let tableView = UITableView()
            XCTAssertEqual(tableView.contentInsetAdjustmentBehavior, .never)
        }
    }
}
