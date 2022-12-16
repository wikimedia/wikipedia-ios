import Foundation
import UIKit

class TalkPageArchivesHostingController: CustomNavigationViewHostingController<TalkPageArchivesView> {
    
    var redView: TempShiftingView?
    let blueView = TempShiftingView(color: .blue, order: 1)
    let greenView = TempShiftingView(color: .green, order: 0)
    
    lazy var barView: ShiftingNavigationBarView = {
        var items: [UINavigationItem] = []
        navigationController?.viewControllers.forEach({ items.append($0.navigationItem) })
        let config = ShiftingNavigationBarView.Config(reappearOnScrollUp: false, shiftOnScrollUp: false)
        return ShiftingNavigationBarView(order: 2, config: config, navigationItems: items, popDelegate: self)
    }()
    
    override var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] {
        if let redView {
            return [barView, blueView, greenView, redView]
        } else {
            return [barView, blueView, greenView]
        }
        
    }
    
    // todo: can we hide some of this in superclass?
    override var data: CustomNavigationViewData {
        return _data
    }
    private let _data: CustomNavigationViewData
    
    init(theme: Theme) {
        let data = CustomNavigationViewData()
        self._data = data
        super.init(rootView: TalkPageArchivesView(data: data), theme: theme)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Archives"
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) { [self] in
            self.redView = TempShiftingView(color: .red, order: 3)
            self.appendShiftingSubview(self.redView!)
        }
        
        apply(theme: theme)
    }
}
