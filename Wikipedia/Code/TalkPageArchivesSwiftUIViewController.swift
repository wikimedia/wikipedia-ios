import Foundation
import UIKit

class AdjustingNavigationBarView: SetupView, CustomNavigationBarSubviewHeightAdjusting {
    let order: Int
    
    var contentHeight: CGFloat {
        return bar.frame.height
    }
    
    func updateContentOffset(contentOffset: CGPoint) -> AdjustingStatus {
        
        var didChangeHeight = false
        
        print("contentOffset: \(contentOffset.y)")
        
        let heightOffset = min(0, max(-bar.frame.height, contentOffset.y))
        
        print("heightOffset: \(heightOffset)")
        
        if (self.equalHeightToContentConstraint?.constant ?? 0) != heightOffset {
            self.equalHeightToContentConstraint?.constant = heightOffset
            didChangeHeight = true
        }
        
        if !didChangeHeight {
            return .complete((heightOffset * -1))
        } else {
            return .adjusting
        }
    }
    
    private var equalHeightToContentConstraint: NSLayoutConstraint?
    private lazy var bar: UINavigationBar = {
        let bar = UINavigationBar(frame: .zero)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()
    
    init(order: Int) {
        self.order = order
        // self.color = color
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        
        translatesAutoresizingMaskIntoConstraints = false
        // backgroundColor = color

        let item = UINavigationItem(title: "Testing!")
        bar.setItems([item], animated: false)
        addSubview(bar)
        
        // top defaultHigh priority allows label to slide upward
        // height 999 priority allows parent view to shrink
        let top = bar.topAnchor.constraint(equalTo: topAnchor)
        top.priority = .defaultHigh
        let bottom = bottomAnchor.constraint(equalTo: bar.bottomAnchor)
        let leading = bar.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = trailingAnchor.constraint(equalTo: bar.trailingAnchor)
        
        let height = heightAnchor.constraint(equalTo: bar.heightAnchor)
        height.priority = UILayoutPriority(999)
        self.equalHeightToContentConstraint = height
        
        NSLayoutConstraint.activate([
            top,
            bottom,
            leading,
            trailing,
            height
        ])
        
        // label.text = "I am a view!"
        
        clipsToBounds = true
    }
}

class TalkPageArchivesHostingController: CustomNavigationBarHostingController<TalkPageArchivesView> {
    
    let redView = AdjustingView(color: .red, order: 0)
    let blueView = AdjustingView(color: .blue, order: 1)
    let greenView = AdjustingView(color: .green, order: 2)
    let barView = AdjustingNavigationBarView(order: 0)
    
    override var customNavigationBarSubviews: [CustomNavigationBarSubviewHeightAdjusting] {
        return [barView, blueView, greenView]
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
