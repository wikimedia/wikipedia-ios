import Foundation

class WKEditorHeaderSelectViewModel {
    enum Configuration {
        case paragraph
        case heading
        case subheading1
        case subheading2
        case subheading3
        case subheading4
    }
    
    let configuration: Configuration
    var isSelected: Bool
    
    init(configuration: Configuration, isSelected: Bool) {
        self.configuration = configuration
        self.isSelected = isSelected
    }
}
