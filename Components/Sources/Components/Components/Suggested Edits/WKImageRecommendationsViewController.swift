import Foundation
import SwiftUI

fileprivate final class WKImageRecommendationsHostingViewController: WKComponentHostingController<WKImageRecommendationsView> {

    let text: String
    init(text: String) {
        self.text = text
        
        super.init(rootView: WKImageRecommendationsView(text: text))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

struct WKImageRecommendationsView: View {
    
    let text: String
    
    var attributedText: AttributedString {
        // TODO: Return proper attributed string
        AttributedString(text)
    }
    
    var body: some View {
        VStack {
            Text(attributedText)
                .lineSpacing(3)
                .environment(\.openURL, OpenURLAction { url in
                    print("Navigate to url: \(url)")
                    return .systemAction(url)
                })
            Spacer()
        }

    }
}

public final class WKImageRecommendationsViewController: WKCanvasViewController {
    
    // MARK: - Properties
    
    let text = "A <b>cactus</b> (plural <b>cacti, cactuses,</b> or less commonly</b>, cactus)</b><sup>[3]</sup> is a member of the <a href=\"https://en.wikipedia.org/wiki/Plant\">plant</a> family <b>Cactaceae</b><sub>[a]</sub>, a family comprising about 127 genera with some 1750 known species of the order <a href=\"https://en.wikipedia.org/wiki/Caryophyllales\">Caryophyllales</a>."

    fileprivate let hostingViewController: WKImageRecommendationsHostingViewController
    
    var attributedText: NSAttributedString? {
        // TODO: Return proper attributed string
        NSAttributedString(string: text)
    }
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isUserInteractionEnabled = true
        textView.attributedText = attributedText
        textView.delegate = self
        return textView
    }()
    
    public override init() {
        self.hostingViewController = WKImageRecommendationsHostingViewController(text: text)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Image recommendations"
        
        // SwiftUI
         addComponent(hostingViewController, pinToEdges: true)

        // UIKit
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: textView.bottomAnchor)
        ])
    }
}

extension WKImageRecommendationsViewController: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
}
