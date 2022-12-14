import Foundation
import UIKit

class TalkPageArchivesHostingController: CustomNavigationViewHostingController<TalkPageArchivesView> {
    
    let redView = TempShiftingView(color: .red, order: 2)
    let blueView = TempShiftingView(color: .blue, order: 1)
    let greenView = TempShiftingView(color: .green, order: 0)
    
    lazy var barView: ShiftingNavigationBarView = {
        var items: [UINavigationItem] = []
        navigationController?.viewControllers.forEach({ items.append($0.navigationItem) })
        return ShiftingNavigationBarView(order: 2, navigationItems: items, popDelegate: self)
    }()
    
    override var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] {
        return [barView, blueView, greenView]
    }
    
    // todo: can we hide some of this in superclass?
    override var data: CustomNavigationViewData {
        return _data
    }
    private let _data: CustomNavigationViewData
    
    init() {
        let data = CustomNavigationViewData()
        self._data = data
        super.init(rootView: TalkPageArchivesView(data: data))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Archives"
        
        view.backgroundColor = .white
    }
}
