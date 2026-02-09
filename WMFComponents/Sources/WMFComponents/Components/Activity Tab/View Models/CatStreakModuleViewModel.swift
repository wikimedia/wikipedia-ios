import WMFData
import SwiftUI

@MainActor
public final class CatStreakModuleViewModel: ObservableObject {
    @Published public var catStreakViewModel: WMFCatStreakViewModel?
    
    private let dataController: WMFActivityTabDataController
    
    public init(dataController: WMFActivityTabDataController = .shared) {
        self.dataController = dataController
    }
    
    public func fetch(localizedStrings: LocalizedStrings) async {
        do {
            // Fetch reading streak
            let streakCount = try await dataController.getReadingStreak()
            
            // Get cat image URL for this streak
            guard let catImageURL = WMFCatStreakImageURLs.getCatImageURL(for: streakCount) else {
                return
            }
            
            // Load cat image using WMFImageDataController for Activity Tab (not widgets)
            let imageData = try await WMFImageDataController.shared.fetchImageData(url: catImageURL)
            
            // Create or update the view model
            let message = streakCount > 0 ? localizedStrings.motivationalMessage(streakCount) : localizedStrings.noStreakMessage
            
            self.catStreakViewModel = WMFCatStreakViewModel(
                catImageData: imageData,
                streakCount: streakCount,
                streakTitle: localizedStrings.streakTitle,
                streakDaysLabel: localizedStrings.daysLabel,
                streakMessage: message,
                zeroStreakMessage: localizedStrings.noStreakMessage
            )
        } catch {
            // On error, don't show the module
            self.catStreakViewModel = nil
        }
    }
    
    public struct LocalizedStrings {
        public let streakTitle: String
        public let daysLabel: String
        public let noStreakMessage: String
        public let motivationalMessage: (Int) -> String
        
        public init(
            streakTitle: String,
            daysLabel: String,
            noStreakMessage: String,
            motivationalMessage: @escaping (Int) -> String
        ) {
            self.streakTitle = streakTitle
            self.daysLabel = daysLabel
            self.noStreakMessage = noStreakMessage
            self.motivationalMessage = motivationalMessage
        }
    }
}
