import UIKit
import WMF

struct ImportedReadingList: Codable {
    let name: String?
    let description: String?
    let list: [String: [Int]]
}

class ReadingListsImportViewController: UIViewController {
    
    private let encodedPayload: String
    let fetcher = PageIDToURLFetcher()
    
    init(encodedPayload: String) {
        self.encodedPayload = encodedPayload
        super.init(nibName: nil, bundle: nil)
    }
    
    private var importedReadingList: ImportedReadingList?
    
    lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            view.trailingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        guard let data = Data(base64Encoded: encodedPayload),
              let result = try? JSONDecoder().decode(ImportedReadingList.self, from: data) else {
            // TODO: Error state
            return
        }
        
        self.importedReadingList = result
        
        guard let urlDict = importedReadingList?.list else {
            return
        }
        
        var siteURLDict: [URL: [Int]] = [:]
        
        for (key, value) in urlDict {
            if let siteURL = NSURL.wmf_URL(withDefaultSiteAndLanguageCode: key) {
                siteURLDict[siteURL] = value
            }
        }
        
        let group = DispatchGroup()
        var finalURLs: [URL] = []
        for (key, value) in siteURLDict {
            group.enter()
            fetcher.fetchPageURLs(key, pageIDs: value) { error in
                DispatchQueue.main.async {
                    group.leave()
                }
            } success: { urls in
                
                DispatchQueue.main.async {
                    finalURLs.append(contentsOf: urls)
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            
            print("whyyyy")
            self.processFinalURLs(finalURLs: finalURLs) { result in
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.label.text = "Success!"
                    case .failure(let error):
                        self.label.text = "Error: \(error.localizedDescription)"
                    }
                }
                
            }
            
            
        }
    }
    
    func processFinalURLs(finalURLs: [URL], completion: @escaping ((Result<Void, Error>) -> Void)) {
        
        let keys = finalURLs.compactMap { $0.wmf_inMemoryKey }
        let dataStore = MWKDataStore.shared()
        
        let articleFetcher = ArticleFetcher()
        articleFetcher.fetchArticleSummaryResponsesForArticles(withKeys: keys) { result in
            
            DispatchQueue.main.async {
                var articles: [WMFArticle] = []
                do {
                    let result = try dataStore.viewContext.wmf_createOrUpdateArticleSummmaries(withSummaryResponses: result)
                    
                    for (_, value) in result {
                        articles.append(value)
                    }
                    
                    _ = try dataStore.readingListsController.createReadingList(named: "Imported Reading List", description: "Imported from Web", with: articles)
                    
                    completion(.success(()))
                } catch let error {
                    completion(.failure(error))
                }
            }
            
        }
    }
}
