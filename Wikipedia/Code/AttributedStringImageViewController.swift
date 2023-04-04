import UIKit
import WMF

class AttributedStringImageViewController: UIViewController {
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        return textView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: textView.topAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: textView.bottomAnchor)
        ])
        
        let sampleHtmlString = "<a href=\"https://en.wikipedia.org/wiki/Main_Page\">Main Page</a> testing here <b>bold</b> and <i>italic</i> and an image: <img src=\"https://images.unsplash.com/photo-1595433707802-6b2626ef1c91?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxleHBsb3JlLWZlZWR8MXx8fGVufDB8fHx8&w=300&q=80\" width=\"300\" height=\"300\" />"
        let mutableAttributedString = NSMutableAttributedString(string: sampleHtmlString)
        self.textView.attributedText = mutableAttributedString
        var fullMatchRanges: [NSRange] = []
        var sourceStrings: [String] = []
        
        let imageTagRegexString = "\\<img.+src\\=(?:\"|\')(.+?)(?:\"|\')(?:.+?)\\>"
        let imageTagRegex = try? NSRegularExpression(pattern: imageTagRegexString)
        imageTagRegex?.enumerateMatches(in: sampleHtmlString, range: NSRange(location: 0, length: sampleHtmlString.count)) { result, flags, stop in
            if let fullMatchRange = result?.range(at: 0),
               let sourceStringRange = result?.range(at: 1) {
                fullMatchRanges.append(fullMatchRange)
                
                let sourceString = (sampleHtmlString as NSString).substring(with: sourceStringRange)
                sourceStrings.append(sourceString)
            }
        }
        
        // begin attempt at inline image
//        if let firstSourceString = sourceStrings.first,
//           let firstMatchRange = fullMatchRanges.first {
//            let task =  URLSession.shared.dataTask(with: URLRequest(url: URL(string:firstSourceString)!)) { data, response, error in
//
//                guard let data = data else {
//                    return
//                }
//
//                sleep(3)
//
//                DispatchQueue.main.async {
//                    if let image = UIImage(data: data) {
//
//                        let imageAttachment = NSTextAttachment()
//                        imageAttachment.image = UIImage(data: data)
//
//                        let imageString = NSAttributedString(attachment: imageAttachment)
//                        mutableAttributedString.replaceCharacters(in: firstMatchRange, with: imageString)
//                        self.textView.attributedText = mutableAttributedString
//                    }
//                }
//
//            }
//
//            task.resume()
//        }
        // end attempt at inline image
        
        // begin simple temp icon
        for(index, fullMatch) in fullMatchRanges.reversed().enumerated() {
            let sourceString = sourceStrings.reversed()[index]

            let imageAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(systemName: "photo")?.withTintColor(.blue)

            let imageString = NSAttributedString(attachment: imageAttachment)
            mutableAttributedString.replaceCharacters(in: fullMatch, with: imageString)
            mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: sourceString, range: NSRange(location: fullMatch.location, length: imageString.length))
        }
             textView.attributedText = mutableAttributedString
         // end simple temp icon
        
        
    }
    
}
