import Foundation

final class TalkPageCoffeeRollViewModel {

    let coffeeRollText: String?
    let talkPageURL: URL?
    let semanticContentAttribute: UISemanticContentAttribute

    init(coffeeRollText: String?, talkPageURL: URL?, semanticContentAttribute: UISemanticContentAttribute) {
        self.coffeeRollText = coffeeRollText
        self.talkPageURL = talkPageURL
        self.semanticContentAttribute = semanticContentAttribute
    }

}
