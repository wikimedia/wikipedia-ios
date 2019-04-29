
import UIKit

//todo: delete

fileprivate class MockTalkPageFetcher: TalkPageFetcher {
    
    override func fetchTalkPage(for name: String, host: String, revisionID: Int64, completion: @escaping (Result<NetworkTalkPage, Error>) -> Void) {
        
        
        if let url = Bundle.main.url(forResource: "TalkPage", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let talkPage = try decoder.decode(NetworkTalkPage.self, from: data)
                talkPage.url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/talk/\(name)")
                talkPage.revisionId = MockArticleRevisionFetcher.revisionId
                completion(.success(talkPage))
            } catch (let error) {
                completion(.failure(error))
            }
        }
    }
}

fileprivate class MockArticleRevisionFetcher: WMFArticleRevisionFetcher {
    
    static var revisionId: Int64 = 894272715
    
    var resultsDictionary: [AnyHashable : Any] {
        return ["batchcomplete": 1,
                "query" : ["pages": [
                    ["ns": 0,
                     "pageid": 2360669,
                     "revisions": [
                        ["minor": 1,
                         "parentid": 894272641,
                         "revid": MockArticleRevisionFetcher.revisionId,
                         "size": 61252]
                        ],
                     "title": "Benty Grange helmet"
                    ]
                    ]
            ]
        ]
    }
    
    override func fetchLatestRevisions(forArticleURL articleURL: URL!, resultLimit numberOfResults: UInt, endingWithRevision revisionId: UInt, failure: WMFErrorHandler!, success: WMFSuccessIdHandler!) -> URLSessionTask! {
        do {
            let revisionQueryResults = try WMFLegacySerializer.models(of: WMFRevisionQueryResults.self, fromArrayForKeyPath: "query.pages", inJSONDictionary: resultsDictionary)
            success(revisionQueryResults)
            return nil
        } catch {
            print("Failure to create WMFRevisionQueryResults")
        }
        
        return nil
    }
}

class TalkPageContainerViewController: ViewController {
    
    private var discussionListViewController: TalkPageDiscussionListViewController!
    var name: String!
    var host: String = "en.wikipedia.org" //todo: smart host
    var dataStore: MWKDataStore!
    
    //todo: delete these
    private let talkPageFetcher = MockTalkPageFetcher(session: Session.shared, configuration: Configuration.current)
    private let articleRevisionFetcher = MockArticleRevisionFetcher()
    
    private var talkPageController: TalkPageController!
    
    private let discussionListEmbedSegue = "discussionListEmbedSegue"

    override func viewDidLoad() {
        super.viewDidLoad()

        fetch()
    }
    
    private func fetch() {
        //todo: no mock talk page / article revision fetchers
        //todo: loading/error/empty states
        talkPageController = TalkPageController(talkPageFetcher: talkPageFetcher, articleRevisionFetcher: articleRevisionFetcher, dataStore: dataStore, name: name, host: host)
        talkPageController.fetchTalkPage { [weak self] (result) in
            switch result {
            case .success(let talkPage):
                self?.discussionListViewController.talkPage = talkPage
            case .failure(let error):
                print("error! \(error)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == discussionListEmbedSegue,
            let listVC = segue.destination as? TalkPageDiscussionListViewController else {
            return
        }
        
        discussionListViewController = listVC
        discussionListViewController.dataStore = dataStore
        discussionListViewController.delegate = self
    }
    
    @IBAction func tappedAddButton(_ sender: UIBarButtonItem) {
        let discussionNewVC = TalkPageDiscussionNewViewController.wmf_viewControllerFromTalkPageStoryboard()
        discussionNewVC.delegate = self
        navigationController?.pushViewController(discussionNewVC, animated: true)
    }

}

extension TalkPageContainerViewController: TalkPageDiscussionNewDelegate {
    func addDiscussion(viewController: TalkPageDiscussionNewViewController) {
        navigationController?.popViewController(animated: true)
    }
}

extension TalkPageContainerViewController: TalkPageDiscussionListDelegate {
    func tappedDiscussion(_ discussion: TalkPageDiscussion, viewController: TalkPageDiscussionListViewController) {
        let replyVC = TalkPageReplyContainerViewController.wmf_viewControllerFromTalkPageStoryboard()
        replyVC.dataStore = dataStore
        replyVC.discussion = discussion
        navigationController?.pushViewController(replyVC, animated: true)
    }
}
