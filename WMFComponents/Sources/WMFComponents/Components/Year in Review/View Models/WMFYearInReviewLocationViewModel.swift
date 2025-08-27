import Foundation
import WMFData

final class WMFYearInReviewSlideLocationViewModel: ObservableObject {
    
    @Published var title: String
    let legacyPageViews: [WMFLegacyPageView]
    let loggingID: String
    @Published var isLoading: Bool = true
    
    init(localizedStrings: WMFYearInReviewViewModel.LocalizedStrings, legacyPageViews: [WMFLegacyPageView], loggingID: String) {
        self.title = ""
        self.legacyPageViews = legacyPageViews
        self.loggingID = loggingID
        self.isLoading = true
    }
    
    func fakeDataCall() {
        Task {
            do {
                try await Task.sleep(for: .seconds(5)) // Replace 5 with your desired delay
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    title = "Fake title: \(legacyPageViews.count)"
                    isLoading = false
                }
            } catch {
                // Handle cancellation or other errors
                print("Task sleep was cancelled or encountered an error: \(error)")
            }
        }
    }
}
