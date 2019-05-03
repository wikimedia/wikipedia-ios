
import UIKit

class TalkPageReplyNewViewController: ViewController {
    
    private let discussion: TalkPageDiscussion
    private let dataStore: MWKDataStore
    private let hiddenView = UIView(frame: .zero)
    
    init(dataStore: MWKDataStore, discussion: TalkPageDiscussion) {
        self.dataStore = dataStore
        self.discussion = discussion
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHiddenView()
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
    } 
}

private extension TalkPageReplyNewViewController {
    func setupHiddenView() {
        hiddenView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hiddenView)
        
        let safeAreaGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            hiddenView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor),
            hiddenView.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor),
            hiddenView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor),
            hiddenView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor),
            hiddenView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}
