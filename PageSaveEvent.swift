import Foundation

class PageSaveEvent : Event {
    
    static let Context = "SavedPages"
    
    enum Action : String {
        case savenew
        case update
        case `import`
        case delete
        case editattempt
        case editrefresh
        case editafterrefresh
    }
    
    init(action: Action) {
        super.init()
//        self.context = PageSaveEvent.Context
//        self.action = action.rawValue
//        self.count = 1
    }
}
