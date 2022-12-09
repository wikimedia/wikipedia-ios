import Foundation
import UIKit
import Combine

class RedView: SetupView, CustomNavigationBarSubviewCollapsing {
    var collapseOrder: Int = 0
    
    func updateContentOffset(contentOffset: CGPoint) {
        // let offsetYConsideringHeight = contentOffset.y + frame.height
        // print(max(contentOffset.y, -frame.height))
        // if contentOffset.y < 0 {
        
        let newHeight = min(0, contentOffset.y)
        if (self.height?.constant ?? 0) != newHeight {
            self.height?.constant = min(0, contentOffset.y)
        }
        
        print(newHeight)
            
            
        // }
        
    }
    
    private var height: NSLayoutConstraint?
    
    override func setup() {
        super.setup()
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .red
        
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        
        addSubview(label)
        
        let top = label.topAnchor.constraint(equalTo: topAnchor)
        top.priority = .defaultHigh
        let bottom = bottomAnchor.constraint(equalTo: label.bottomAnchor)
        let leading = label.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = trailingAnchor.constraint(equalTo: label.trailingAnchor)
        
        let height = heightAnchor.constraint(equalTo: label.heightAnchor)
        height.priority = UILayoutPriority(999)
        self.height = height
        
        NSLayoutConstraint.activate([
            top,
            bottom,
            leading,
            trailing,
            height
        ])
        
        label.text = "RedView"
    }
}

class BlueView: SetupView, CustomNavigationBarSubviewCollapsing {
    
    var collapseOrder: Int = 1
    
    func updateContentOffset(contentOffset: CGPoint) {
        // print(contentOffset)
    }
    
    override func setup() {
        super.setup()
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .blue
        
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        wmf_addSubviewWithConstraintsToEdges(label)
        label.text = "BlueView"
        
    }
}

class GreenView: SetupView, CustomNavigationBarSubviewCollapsing {
    
    var collapseOrder: Int = 2
    
    func updateContentOffset(contentOffset: CGPoint) {
        // print(contentOffset)
    }
    
    override func setup() {
        super.setup()
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .green
        
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        wmf_addSubviewWithConstraintsToEdges(label)
        label.text = "GreenView"
    }
}

class TalkPageArchivesContainerViewController: CustomNavigationBarContainerViewController {
    
    let redView = RedView(frame: .zero)
    let blueView = BlueView(frame: .zero)
    let greenView = GreenView(frame: .zero)
    
    override var collapsingNavigationBarSubviews: [CustomNavigationBarSubviewCollapsing] {
        return [redView, blueView, greenView]
    }
    
    override var childContentViewController: UIViewController {
        return hostingVC
    }
    
    lazy var hostingVC = {
        let talkPageArchivesView = TalkPageArchivesView(contentOffset: contentOffset)
        let hostingVC = TalkPageArchivesHostingController(rootView: talkPageArchivesView)
        return hostingVC
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
    }
}
