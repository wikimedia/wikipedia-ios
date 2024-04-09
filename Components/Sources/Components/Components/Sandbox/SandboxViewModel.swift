import Foundation
import WKData

class SandboxViewModel {

    // MARK: Nested Entities

    struct UserSandbox {
        let title: String
        let category: String
        let commentCount: Int
    }

    struct CategorySandbox{
        let categoryTitle: String
        let sandboxCount: Int
        let followerCount: Int
    }

    // MARK: Properties

    let userSandboxes: [UserSandbox]
    let categorySandboxes: [CategorySandbox]

    init(userSandboxes: [UserSandbox], categorySandboxes: [CategorySandbox]) {
        self.userSandboxes = userSandboxes
        self.categorySandboxes = categorySandboxes
    }

    func fetchUserSandboxes() {

        guard let username = dataStore.authenticationManager.loggedInUsername else {
            return
        }
        let testWikiLanguage = WKLanguage(languageCode: "test", languageVariantCode: nil)
        let sandboxDataController = WKSandboxDataController()
        sandboxDataController.fetchSandboxArticles(project: WKProject.wikipedia(testWikiLanguage), username: username) { result in
            switch result {
            case .success(let titles):
                print(titles)
            case .failure(let error):
                print(error)
            }
        }

    }

}


