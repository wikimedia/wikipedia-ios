import Foundation

extension ViewController {
    func presentArticleErrorRecovery(with article: WMFArticle) {
        switch article.error {
        case .apiFailed:
            let alert = UIAlertController(title: article.error.localizedDescription, message: nil, preferredStyle: .actionSheet)
            let retry = UIAlertAction(title: CommonStrings.retryActionTitle, style: .default) { (action) in
                article.retryDownload()
            }
            alert.addAction(retry)
            let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .default)
            alert.addAction(cancel)
            present(alert, animated: true)
        default:
            break
        }
       
    }
}
