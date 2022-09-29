import SwiftUI
import WMF

class UserInput: ObservableObject {
    @Published var text: String = ""
}

class VanishAccountContainerViewController: UIViewController {
    
    enum LocalizedStrings {
        static let backConfirmationTitle = WMFLocalizedString("vanish-account-back-confirm-title", value: "Are you sure you want to discard this vanish request?", comment: "Title of confirmation alert on vanishing request screen, if user taps Back after filling out information.")
        static let backConfirmationDiscard = WMFLocalizedString("vanish-account-back-confirm-discard", value: "Discard Request", comment: "Text of confirmation alert discard option on vanishing request screen, if user taps Back after filling out information. This option backs out of the screen.")
        static let backConfirmationKeepEditing = WMFLocalizedString("vanish-account-back-confirm-keep-editing", value: "Keep Editing", comment: "Text of confirmation alert keep editing option on vanishing request screen, if user taps Back after filling out information. This option keeps them on the screen to continue editing.")
    }
    
    private let hostingController: UIHostingController<VanishAccountContentView>
    let userInput = UserInput()
    
    init(title: String, theme: Theme, username: String) {
        hostingController = VanishAccountCustomUIHostingController(title: title, theme: theme, username: username, userInput: userInput)
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        // Custom back button, so we can present the action sheet
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(.caretLeft, target: self, action: #selector(tappedBack))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    @objc func tappedBack() {
        if userInput.text.count > 0 {
            let alertController = UIAlertController(title: LocalizedStrings.backConfirmationTitle, message: nil, preferredStyle: .actionSheet)
            let discardAction = UIAlertAction(title: LocalizedStrings.backConfirmationDiscard, style: .destructive) { action in
                self.navigationController?.popViewController(animated: true)
            }
            let keepEditingAction = UIAlertAction(title: LocalizedStrings.backConfirmationKeepEditing, style: .cancel)
            
            alertController.addAction(discardAction)
            alertController.addAction(keepEditingAction)
            alertController.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
            
            present(alertController, animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}

class VanishAccountCustomUIHostingController: UIHostingController<VanishAccountContentView> {
    
    init(title: String, theme: Theme, username: String, userInput: UserInput) {
        super.init(rootView: VanishAccountContentView(userInput: userInput, theme: theme, username: username))
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
