import UIKit

protocol PageEditorViewControllerDelegate: AnyObject {
    func pageEditorDidCancelEditing(_ pageEditor: PageEditorViewController, navigateToURL: URL?)
}

class PageEditorViewController: UIViewController {
    
    lazy var wikitextEditor: NativeWikitextEditorViewController = {
        let editor = NativeWikitextEditorViewController(delegate: self, theme: theme)
        return editor
    }()
    
    internal let dataStore: MWKDataStore
    private let wikitextFetcher: WikitextFetcher
    internal let pageURL: URL
    private let sectionID: Int?
    private let selectedTextEditInfo: SelectedTextEditInfo?
    private let theme: Theme
    
    private lazy var navigationItemController: PageEditorNavigationItemController = {
        let navigationItemController = PageEditorNavigationItemController(navigationItem: navigationItem)
        navigationItemController.delegate = self
        return navigationItemController
    }()
    
    private weak var delegate: PageEditorViewControllerDelegate?
    
    init(pageURL: URL, sectionID: Int?, dataStore: MWKDataStore, selectedTextEditInfo: SelectedTextEditInfo? = nil, delegate: PageEditorViewControllerDelegate, theme: Theme) {
        self.pageURL = pageURL
        self.sectionID = sectionID
        self.wikitextFetcher = WikitextFetcher(session: dataStore.session, configuration: dataStore.configuration)
        self.dataStore = dataStore
        self.selectedTextEditInfo = selectedTextEditInfo
        self.delegate = delegate
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        addChildWikitextEditor()
        loadWikitext()
        apply(theme: theme)
    }
    
    private func setupNavigationBar() {
        navigationItemController.undoButton.isEnabled = false
        navigationItemController.redoButton.isEnabled = false
    }
    
    private func addChildWikitextEditor() {
        addChild(wikitextEditor)
        wikitextEditor.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wikitextEditor.view)
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: wikitextEditor.view.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: wikitextEditor.view.trailingAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: wikitextEditor.view.topAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: wikitextEditor.view.bottomAnchor)
        ])
        wikitextEditor.didMove(toParent: self)
    }
    
    private func loadWikitext() {
        wikitextFetcher.fetchSection(with: sectionID, articleURL: pageURL) { [weak self] (result) in
            DispatchQueue.main.async {
                
                guard let self else {
                    return
                }
                
                switch result {
                case .failure(let error):
                    // TODO: error
                    print(error)
                case .success(let response):
                    self.wikitextEditor.setupInitialText(response.wikitext)
                }
            }
        }
    }
}

extension PageEditorViewController: NativeWikitextEditorDelegate {
    func wikitextViewDidChange(_ textView: UITextView) {
        navigationItemController.undoButton.isEnabled = (textView.undoManager?.canUndo ?? false)
        navigationItemController.redoButton.isEnabled = (textView.undoManager?.canRedo ?? false)
    }
    
    func findKeyboardBarDidShow(_ keyboardBar: FindAndReplaceKeyboardBar) {
        navigationItemController.progressButton.isEnabled = false
        navigationItemController.readingThemesControlsToolbarItem.isEnabled = false
    }
    
    func findKeyboardBarDidHide(_ keyboardBar: FindAndReplaceKeyboardBar) {
        navigationItemController.progressButton.isEnabled = true
        navigationItemController.readingThemesControlsToolbarItem.isEnabled = true
    }
}

extension PageEditorViewController: PageEditorNavigationItemControllerDelegate {
    func pageEditorNavigationItemController(_ pageEditorNavigationItemController: PageEditorNavigationItemController, didTapProgressButton progressButton: UIBarButtonItem) {
        print("progress")
    }
    
    func pageEditorNavigationItemController(_ pageEditorNavigationItemController: PageEditorNavigationItemController, didTapCloseButton closeButton: UIBarButtonItem) {
        // todo: show destructive alert
        // todo: pass along url if needed
        delegate?.pageEditorDidCancelEditing(self, navigateToURL: nil)
    }
    
    func pageEditorNavigationItemController(_ pageEditorNavigationItemController: PageEditorNavigationItemController, didTapUndoButton undoButton: UIBarButtonItem) {
        wikitextEditor.undo()
    }
    
    func pageEditorNavigationItemController(_ pageEditorNavigationItemController: PageEditorNavigationItemController, didTapRedoButton redoButton: UIBarButtonItem) {
        wikitextEditor.redo()
    }
    
    func pageEditorNavigationItemController(_ pageEditorNavigationItemController: PageEditorNavigationItemController, didTapReadingThemesControlsButton readingThemesControlsButton: UIBarButtonItem) {
        print("show reading themes")
    }
    
    func pageEditorNavigationItemController(_ pageEditorNavigationItemController: PageEditorNavigationItemController, didTapEditNoticesButton: UIBarButtonItem) {
        print("show edit notices")
    }
}

extension PageEditorViewController: Themeable {
    func apply(theme: Theme) {
        guard isViewLoaded else {
            return
        }
        
        wikitextEditor.apply(theme: theme)
        navigationItemController.apply(theme: theme)
    }
}
