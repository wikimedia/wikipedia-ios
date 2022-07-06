import UIKit
import WMF

class TalkPageViewController: ViewController {
    
    private let talkPageTitle: String
    private let siteURL: URL
    var stackView: UIStackView?
    var introText: String?
    
    convenience init?(url: URL, theme: Theme) {
        guard let talkPageTitle = url.wmf_title,
              let siteURL = (url as NSURL).wmf_site else {
            return nil
        }
        self.init(talkPageTitle: talkPageTitle, siteURL: siteURL, theme: theme)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(talkPageTitle: String, siteURL: URL, theme: Theme) {
        self.talkPageTitle = talkPageTitle
        self.siteURL = siteURL
        super.init(theme: theme)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "New talk page beta testing"
        view = UIView()
        view.backgroundColor = self.theme.colors.baseBackground
        
        self.addUIStackView()
        
        let fetcher = TalkPageFetcher()
        fetcher.fetchTalkPageContent(talkPageTitle: talkPageTitle, siteURL: siteURL) { result in
            switch result {
            case .success(let talkPageItems):
                if let firstOtherContent = talkPageItems.first?.otherContent {
                    DispatchQueue.main.async {
                        self.introText = firstOtherContent
                        self.addIntroLabel(intro: firstOtherContent)
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func addUIStackView() {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .horizontal
        stackView.distribution = .fill
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        let centerXConstraint = stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let topConstraint = stackView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 20)
        let widthConstraint = stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85)
        let heightConstraint = stackView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)

        view.addConstraints([centerXConstraint, topConstraint, widthConstraint, heightConstraint])
        
        stackView.backgroundColor = theme.colors.paperBackground
        stackView.layer.cornerRadius = 3
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        self.stackView = stackView
    }
    
    func addIntroLabel(intro: String) {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = intro.byAttributingHTML(with: .footnote, boldWeight: .semibold, matching: traitCollection, color: theme.colors.primaryText, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true, tagMapping: ["a": "b"])
        label.numberOfLines = 0
        stackView?.addArrangedSubview(label)
        label.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedIntro))
        label.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tappedIntro() {
        guard let introText = introText else {
            return
        }

        let talkPage = TalkPageWebViewController(introText: introText, talkPageTitle: talkPageTitle, siteURL: siteURL, theme: theme)
        navigationController?.pushViewController(talkPage, animated: true)
    }
}
