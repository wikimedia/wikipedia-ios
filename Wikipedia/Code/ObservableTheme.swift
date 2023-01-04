import Foundation
import WMF

final class ObservableTheme: ObservableObject {
    @Published var theme: Theme
    
    init(theme: Theme) {
        self.theme = theme
    }
}
