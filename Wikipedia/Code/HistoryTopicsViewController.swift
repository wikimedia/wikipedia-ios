import Foundation
import UIKit
import WMF
import CoreML
import SwiftUI

class HistoryTopicsViewController: UIViewController {
    
    var dataStore: MWKDataStore?
    
    var mapping: [WMFArticle: [String]] = [:]
    var topicsMapping: [String: [WMFArticle]] = [:]
    private let spinner = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        spinner.startAnimating()
        
        let articleRequest = WMFArticle.fetchRequest()
        articleRequest.predicate = NSPredicate(format: "viewedDate != NULL")
        articleRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WMFArticle.viewedDateWithoutTime, ascending: false), NSSortDescriptor(keyPath: \WMFArticle.viewedDate, ascending: false)]
        
        guard let dataStore = dataStore else {
            return
        }
        
        Task {
            let articles: [WMFArticle]
            do {
                articles = try dataStore.viewContext.fetch(articleRequest)
            } catch {
                print("Fetch failed: \(error)")
                return
            }

            // Fetch Wikidata outlinks off the main thread
        
            Task.detached {
                let limitedArticles = Array(articles.prefix(500))
                let batchSize = 20

                for batchStart in stride(from: 0, to: limitedArticles.count, by: batchSize) {
                    let batch = Array(limitedArticles[batchStart..<min(batchStart + batchSize, limitedArticles.count)])
                    
                    await withTaskGroup(of: (WMFArticle, [String]?).self) { group in
                        for article in batch {
                            guard let url = article.url,
                                  let articleTitle = url.wmf_title?.denormalizedPageTitle,
                                  let articleWikiSiteURL = url.wmf_site else {
                                continue
                            }

                            group.addTask {
                                do {
                                    let outlinks = try await self.fetchWikidataOutlinks(articleWikiSiteURL: articleWikiSiteURL, articleTitle: articleTitle)
                                    return (article, outlinks)
                                } catch {
                                    print("❌ Failed to fetch outlinks for \(articleTitle): \(error)")
                                    return (article, nil)
                                }
                            }
                        }

                        for await (article, outlinks) in group {
                            if let outlinks = outlinks {
                                await MainActor.run {
                                    self.mapping[article] = outlinks
                                }
                                print("🔗 \(article.displayTitle ?? "Untitled"): \(outlinks.count) outlinks")
                            }
                        }
                    }
                }

                await MainActor.run {
                    self.predictTopics()
                    self.spinner.stopAnimating()
                    self.showTopicsView()
                }
            }
        }
    }
    
    func fetchWikidataOutlinks(articleWikiSiteURL: URL, articleTitle: String) async throws -> [String] {
        // Step 1: Build the API endpoint
        let characterSet = CharacterSet.wmf_encodeURIComponentAllowed
        // let encodedTitle = articleTitle.addingPercentEncoding(withAllowedCharacters: characterSet) ?? articleTitle
        let endpoint = articleWikiSiteURL.appendingPathComponent("w/api.php")
        
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "titles", value: articleTitle),
            URLQueryItem(name: "generator", value: "links"),
            URLQueryItem(name: "prop", value: "pageprops"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "gpllimit", value: "max")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        // Step 2: Perform the API request
        let (data, _) = try await URLSession.shared.data(from: url)

        // Step 3: Parse the JSON response
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let query = json["query"] as? [String: Any],
            let pages = query["pages"] as? [String: Any]
        else {
            return []
        }

        // Step 4: Collect Q-IDs from pageprops
        var qids: [String] = []

        for (_, pageData) in pages {
            if let pageDict = pageData as? [String: Any],
               let pageProps = pageDict["pageprops"] as? [String: Any],
               let wikidataId = pageProps["wikibase_item"] as? String {
                qids.append(wikidataId)
            }
        }

        return qids
    }
    
    func predictTopics() {
        
        for (article, outlinks) in mapping {
            // Join the Q-IDs into a single string, separated by newlines (same as training)
            let inputText = outlinks.joined(separator: "\n")

            do {
                let model = try ArticleTopics(configuration: MLModelConfiguration())
                let prediction = try model.prediction(text: inputText)
                topicsMapping[prediction.label, default: []].append(article)
                // or prediction.labelProbabilities for confidence
            } catch {
                print("❌ Prediction failed: \(error)")
                return
            }
        }
    }
    
    func printTopics() {
        for (topic, articles) in topicsMapping {
            print("-------\(topic)-------\n")
            for article in articles {
                print("\(article.displayTitle ?? "nil")\n")
            }
        }
    }
    
    func showTopicsView() {
            let swiftUIView = TopicsListView(topicsMapping: self.topicsMapping)
            let hostingController = UIHostingController(rootView: swiftUIView)

            // Clean up any old views if needed
            self.children.forEach { $0.removeFromParent() }
            self.view.subviews.forEach { $0.removeFromSuperview() }

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
}

struct TopicsListView: View {
    let topicsMapping: [String: [WMFArticle]]

    var body: some View {
        List {
            ForEach(topicsMapping.keys.sorted(), id: \.self) { topic in
                Section(header: Text(topic).font(.headline)) {
                    ForEach(topicsMapping[topic] ?? [], id: \.objectID) { article in
                        Text(article.displayTitle ?? "Untitled")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

extension CharacterSet {
    static let wmf_encodeURIComponentAllowed: CharacterSet = {
        // Match JavaScript's encodeURIComponent behavior
        let allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()"
        return CharacterSet(charactersIn: allowedCharacters)
    }()
}
