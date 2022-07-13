import IntentsUI
import SwiftUI
import WMF

// As an example, this extension's Info.plist has been configured to handle interactions for INSendMessageIntent.
// You will want to replace this or add other intents as appropriate.
// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

// You can test this example integration by saying things to Siri like:
// "Send a message using <myApp>"

class IntentViewController: UIViewController, INUIHostedViewControlling {
    
    var hostingViewController: UIHostingController<ArticleIntentView>?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
        
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configureView(for parameters: Set<INParameter>, of interaction: INInteraction, interactiveBehavior: INUIInteractiveBehavior, context: INUIHostedViewContext, completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {
        // Do configuration here, including preparing views and calculating a desired size for presentation.
        
        let dataStore = MWKDataStore()
        guard let generateReadingListIntent = interaction.intent as? GenerateReadingListIntent,
           let readingListName = generateReadingListIntent.readingListName,
              let readingList = dataStore.viewContext.wmf_fetch(objectForEntityName: "ReadingList", withValue: readingListName, forKey: "canonicalName") as? ReadingList else {
            completion(false, parameters, CGSize.zero)
            return
        }
        
        let entriesRequest: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        entriesRequest.predicate = NSPredicate(format: "list == %@", readingList)
        entriesRequest.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
        guard let entries = try? dataStore.viewContext.fetch(entriesRequest),
              !entries.isEmpty else {
            completion(false, parameters, CGSize.zero)
            return
        }
        
        let articles: [WMFArticle] = entries.compactMap { entry in
            guard let inMemoryKey = entry.inMemoryKey else {
                return nil
            }
            return dataStore.fetchArticle(withKey: inMemoryKey.databaseKey, variant: inMemoryKey.languageVariantCode)
        }
        
        let intentArticles = articles.map { IntentArticle(title: $0.displayTitle ?? "", subtitle: $0.capitalizedWikidataDescriptionOrSnippet ?? "", imageUrl: $0.imageURL(forWidth: 100)) }
        let articleIntentView = ArticleIntentView(articles: intentArticles)
        
        let hostingViewController = UIHostingController(rootView: articleIntentView)
        addChild(hostingViewController)
        hostingViewController.view.frame = view.frame
        view.addSubview(hostingViewController.view)
        hostingViewController.didMove(toParent: self)
        
        self.hostingViewController = hostingViewController
        
        completion(true, parameters, self.desiredSize)
    }
    
    var desiredSize: CGSize {
        return self.extensionContext!.hostedViewMaximumAllowedSize
    }
    
}

struct IntentArticle: Hashable {
    let title: String
    let subtitle: String
    let imageUrl: URL?
}

struct ArticleIntentRow: View {
    
    let article: IntentArticle
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(article.title)
                    .lineLimit(1)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(article.subtitle)
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if #available(iOS 15.0, *) {
                if article.imageUrl == nil {
                    Color.clear
                        .frame(width: 1, height: 100)
                } else {
                    AsyncImage(url: article.imageUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                 .frame(width: 100, height: 100)
                                 .clipped()
                        case .failure:
                            Image(systemName: "photo")
                                .frame(width: 100, height: 100)
                        @unknown default:
                            // Since the AsyncImagePhase enum isn't frozen,
                            // we need to add this currently unused fallback
                            // to handle any new cases that might be added
                            // in the future:
                            EmptyView()
                                .frame(width: 100, height: 100)
                        }
                    }
                }
            } else {
                // nothin
            }
        }
        .padding(8)
    }
}

struct ArticleIntentView: View {
    
    let articles: [IntentArticle]
    
    var body: some View {
        List {
            ForEach(articles, id: \.self) { article in
                ArticleIntentRow(article: article)
            }
        }
        .listStyle(.plain)
    }
}
