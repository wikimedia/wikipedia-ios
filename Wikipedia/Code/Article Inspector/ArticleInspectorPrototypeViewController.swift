
import UIKit

class ArticleInspectorPrototypeViewController: ViewController {
    
    @IBOutlet weak var testLabel: UILabel!
    var webViewHTML: String? = nil
    var articleTitle: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        testLabel.text = webViewHTML
        if let articleTitle = articleTitle {
            fetchAnnotatedHTML(title: articleTitle)
        }
    }
    
    func fetchAnnotatedHTML(title: String) {
        let url = URL(string: "https://wikiwho-ios-experiments.wmflabs.org/whocolor/\(title)/")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            print(String(data: data!, encoding: .utf8))
        }
        task.resume()
    }

}
