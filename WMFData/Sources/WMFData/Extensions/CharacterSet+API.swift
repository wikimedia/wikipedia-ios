import Foundation

extension CharacterSet {
    static let urlQueryComponentAllowed: CharacterSet = {
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove(charactersIn: "+&=")
        return characterSet
    }()
}
