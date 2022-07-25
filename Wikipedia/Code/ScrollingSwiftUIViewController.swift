import UIKit
import SwiftUI
import WMF

extension Notification.Name {
     static let swiftUITextfieldDidBeginEditing = Notification.Name("swiftUITextfieldDidBeginEditing")
     static let swiftUITextfieldDidEndEditing = Notification.Name("swiftUITextfieldDidEndEditing")
}

class NavigationBarHiddenUIHostingController<Content: View>: UIHostingController<Content> {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

/// Allows the use of a limited amount of scrolling SwiftUI, embedded within a UIScrollView.
/// This subclasses ViewController so that we can continue to use our custom navigation bar setup
class ScrollingSwiftUIViewController<T>: ViewController where T: View {
    
    private let contentView: T
    private let respondsToTextfieldEdits: Bool
    private let isBarHidingEnabled: Bool
    
    lazy var hostingScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        return scrollView
    }()
    
    lazy var hostingController: UIHostingController<T> = {
        let hostingController = NavigationBarHiddenUIHostingController(rootView: contentView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }()
    
    private lazy var doneButton = UIBarButtonItem(title: CommonStrings.doneTitle, style: .done, target: self, action: #selector(tappedDone))
    
    init(contentView: T, title: String, respondsToTextfieldEdits: Bool = false, isBarHidingEnabled: Bool = false) {
        self.contentView = contentView
        self.respondsToTextfieldEdits = respondsToTextfieldEdits
        self.isBarHidingEnabled = isBarHidingEnabled
        
        super.init()
        
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHostingScrollView()
        setupHostingController()
        
        navigationBar.isBarHidingEnabled = isBarHidingEnabled
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.backgroundColor = theme.colors.paperBackground
        
        if respondsToTextfieldEdits {
            NotificationCenter.default.addObserver(self, selector: #selector(textfieldDidBeginEditing), name: .swiftUITextfieldDidBeginEditing, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(textfieldDidEndEditing), name: .swiftUITextfieldDidEndEditing, object: nil)
        }
    }
    
    @objc func textfieldDidBeginEditing() {
        navigationItem.rightBarButtonItem = doneButton
        navigationBar.updateNavigationItems()
    }
    
    @objc func textfieldDidEndEditing() {
        navigationItem.rightBarButtonItem = nil
        navigationBar.updateNavigationItems()
    }
    
    @objc func tappedDone() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func setupHostingScrollView() {
        
        view.addSubview(hostingScrollView)
        let topConstraint = hostingScrollView.topAnchor.constraint(equalTo: view.topAnchor)
        let bottomConstraint = hostingScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        let leadingConstraint = hostingScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailingConstraint = hostingScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        view.addConstraints([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
        
        self.scrollView = hostingScrollView
    }
    
    func setupHostingController() {
        addChild(hostingController)
        
        hostingScrollView.wmf_addSubviewWithConstraintsToEdges(hostingController.view)
        let hostingWidth = hostingController.view.widthAnchor.constraint(equalTo: hostingScrollView.widthAnchor)
        
        hostingScrollView.addConstraint(hostingWidth)
        hostingController.didMove(toParent: self)
    }
        
}
