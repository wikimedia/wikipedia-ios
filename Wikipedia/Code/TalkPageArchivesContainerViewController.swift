import Foundation
import UIKit
import Combine

class AdjustingView: SetupView, CustomNavigationBarSubviewHeightAdjusting {
    let order: Int
    let color: UIColor
    
    var contentHeight: CGFloat {
        return label.frame.height
    }
    
    func updateContentOffset(contentOffset: CGPoint) -> AdjustingStatus {
        
        // let offsetYConsideringHeight = contentOffset.y + frame.height
        // print(max(contentOffset.y, -frame.height))
        // if contentOffset.y < 0 {
        
        var didChangeHeight = false
        
        // content
        
        print("contentOffset: \(contentOffset.y)")
        
        // Cool example of last item only collapsing to a certain amount
        // let heightOffset = order == 2 ? min(0, max((-label.frame.height/2), contentOffset.y)) : min(0, max(-label.frame.height, contentOffset.y))
        
        let heightOffset = min(0, max(-label.frame.height, contentOffset.y))
        
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
    private lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    init(color: UIColor, order: Int) {
        self.order = order
        self.color = color
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        super.setup()
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = color

        addSubview(label)
        
        // top defaultHigh priority allows label to slide upward
        // height 999 priority allows parent view to shrink
        let top = label.topAnchor.constraint(equalTo: topAnchor)
        top.priority = .defaultHigh
        let bottom = bottomAnchor.constraint(equalTo: label.bottomAnchor)
        let leading = label.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = trailingAnchor.constraint(equalTo: label.trailingAnchor)
        
        let height = heightAnchor.constraint(equalTo: label.heightAnchor)
        height.priority = UILayoutPriority(999)
        self.equalHeightToContentConstraint = height
        
        NSLayoutConstraint.activate([
            top,
            bottom,
            leading,
            trailing,
            height
        ])
        
        label.text = "I am a view!"
        
        clipsToBounds = true
    }
}


class TalkPageArchivesContainerViewController: CustomNavigationBarContainerViewController {
    
    let redView = AdjustingView(color: .red, order: 0)
    let blueView = AdjustingView(color: .blue, order: 1)
    let greenView = AdjustingView(color: .green, order: 2)
    
    override var customNavigationBarSubviews: [CustomNavigationBarSubviewHeightAdjusting] {
        return [redView, blueView, greenView]
    }
    
    override var childContentViewController: UIViewController {
        return hostingVC
    }
    
    lazy var hostingVC = {
        let talkPageArchivesView = TalkPageArchivesView(data: data)
        let hostingVC = TalkPageArchivesHostingController(rootView: talkPageArchivesView)
        return hostingVC
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
    }
}
