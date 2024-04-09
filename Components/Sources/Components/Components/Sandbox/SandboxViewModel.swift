import Foundation
import WKData

public class SandboxViewModel {

    // MARK: Nested Entities

    struct UserSandbox {
        let title: String
        let category: String
        let commentCount: Int
    }

    public struct CategorySandbox {
        public let categoryTitle: String
        public let sandboxCount: Int
        public let followerCount: Int

        public init(categoryTitle: String, sandboxCount: Int, followerCount: Int) {
            self.categoryTitle = categoryTitle
            self.sandboxCount = sandboxCount
            self.followerCount = followerCount
        }
    }

    // MARK: Properties
    let username: String
    var userSandboxes: [UserSandbox] = []
    let categorySandboxes: [CategorySandbox]

    public init(username: String, categorySandboxes: [CategorySandbox]) {
        self.username = username
        self.categorySandboxes = categorySandboxes
        fetchUserSandboxes()
    }

    func fetchUserSandboxes() {
        let testWikiLanguage = WKLanguage(languageCode: "test", languageVariantCode: nil)
        let sandboxDataController = WKSandboxDataController()
        sandboxDataController.fetchSandboxArticles(project: WKProject.wikipedia(testWikiLanguage), username: username) { result in
            switch result {
            case .success(let titles):
                self.userSandboxes = self.populateUserSandboxes(titles: titles)
                print(titles)
            case .failure(let error):
                print(error)
            }
        }

    }

    func populateUserSandboxes(titles: [String]) -> [UserSandbox] {
        var sandboxes = [UserSandbox]()
        for item in titles {
            let sandbox = UserSandbox(title: item, category: "category ", commentCount: Int.random(in: 0..<10))
            sandboxes.append(sandbox)
        }
        return sandboxes
    }

}


