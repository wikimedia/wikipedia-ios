import Foundation
import UIKit
import SwiftUI

class TalkPageArchivesHostingController<Content>: CustomNavigationViewHostingController<Content> where Content: View {
    
    let redView = TempShiftingView(color: .red, order: 2)
    let blueView = TempShiftingView(color: .blue, order: 1)
    let greenView = TempShiftingView(color: .green, order: 0)
    let barView = ShiftingNavigationBarView(order: 0)
    
    override var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] {
        return [barView, blueView, greenView]
    }
    
    // todo: can we hide some of this in superclass?
    override var data: CustomNavigationViewData {
        return _data
    }
    private let _data: CustomNavigationViewData
    
    init(data: CustomNavigationViewData, content: Content) {
        self._data = data
        super.init(rootView: content)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
    }
}
