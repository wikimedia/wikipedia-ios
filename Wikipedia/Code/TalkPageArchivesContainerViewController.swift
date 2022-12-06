import Foundation
import UIKit
import Combine

class RedView: SetupView, CustomNavigationBarSubview {
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

class BlueView: SetupView, CustomNavigationBarSubview {
    
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

class GreenView: SetupView, CustomNavigationBarSubview {
    
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

class TalkPageArchivesContainerViewController: UIViewController, CustomNavigationBarContainerViewController {
    
    // Any way to hide these elsewhere? Maybe some sort of superclass?
    var contentOffset = CustomNavigationBarContentOffset()
    var contentOffsetCancellable: AnyCancellable?
    
    let redView = RedView(frame: .zero)
    let blueView = BlueView(frame: .zero)
    let greenView = GreenView(frame: .zero)
    
    var stackedNavigationViews: [CustomNavigationBarSubview] {
        return [redView, blueView, greenView]
    }
    
    lazy var hostingVC = {
        let talkPageArchivesView = TalkPageArchivesView(contentOffset: contentOffset)
        let hostingVC = TalkPageArchivesHostingController(rootView: talkPageArchivesView)
        return hostingVC
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setupCustomNavigationBar(withChildViewController: hostingVC)
    }
}
