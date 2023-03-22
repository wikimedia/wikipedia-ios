import UIKit

class PageEditorViewController: UIViewController {
    
    lazy var wikitextEditor: NativeWikitextEditorViewController = {
        let editor = NativeWikitextEditorViewController(delegate: self)
        return editor
    }()
    
    private let wikitextFetcher: SectionFetcher
    private let pageURL: URL
    private let sectionID: Int?
    private let selectedTextEditInfo: SelectedTextEditInfo?
    private let theme: Theme
    
    init(pageURL: URL, sectionID: Int?, wikitextFetcher: SectionFetcher, selectedTextEditInfo: SelectedTextEditInfo? = nil, theme: Theme) {
        self.pageURL = pageURL
        self.sectionID = sectionID
        self.wikitextFetcher = wikitextFetcher
        self.selectedTextEditInfo = selectedTextEditInfo
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChildWikitextEditor()
        loadWikitext()
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
        // enable publish button if length > 0
        // enable undo/redo buttons
    }
}
