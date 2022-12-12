import Foundation
import UIKit

class TalkPageArchivesHostingController: CustomNavigationBarHostingController<TalkPageArchivesView> {
    
    let redView = AdjustingView(color: .red, order: 2)
    let blueView = AdjustingView(color: .blue, order: 1)
    let greenView = AdjustingView(color: .green, order: 0)
    
    override var customNavigationBarSubviews: [CustomNavigationBarSubviewHeightAdjusting] {
        return [redView, blueView, greenView]
    }
    
    // todo: can we hide some of this in superclass?
    override var data: CustomNavigationBarData {
        return _data
    }
    private let _data: CustomNavigationBarData
    
    init() {
        let data = CustomNavigationBarData()
        self._data = data
        super.init(rootView: TalkPageArchivesView(data: data))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
    }
}
