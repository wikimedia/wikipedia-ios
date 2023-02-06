import Foundation
import Combine

class ShiftingTopViewsData: ObservableObject {
    @Published var scrollAmount = CGFloat(0)
    @Published var totalHeight = CGFloat(0)
    @Published var isLoading = false
}
