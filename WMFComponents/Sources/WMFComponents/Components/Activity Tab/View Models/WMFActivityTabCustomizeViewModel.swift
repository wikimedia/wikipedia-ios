import WMFData
import SwiftUI
import Combine

@MainActor
public final class WMFActivityTabCustomizeViewModel: ObservableObject {
    let localizedStrings: LocalizedStrings
    
    @Published var isTimeSpentReadingOn: Bool = true
    @Published var isReadingInsightsOn: Bool = true
    @Published var isEditingInsightsOn: Bool = true
    @Published var isAllTimeImpactOn: Bool = true
    @Published var isLastInAppDonationOn: Bool = true
    @Published var isTimelineOfBehaviorOn: Bool = true
    
    private let dataController = WMFActivityTabDataController.shared
    
    private var cancellables = Set<AnyCancellable>()

    public init(localizedStrings: LocalizedStrings) {
        self.localizedStrings = localizedStrings
        
        Task {
            await updateFromDataController()
            bindPublishedProperties()
        }
    }
    
    private func updateFromDataController() async {
        let isTimeSpentReadingOn = await dataController.isTimeSpentReadingOn
        let isReadingInsightsOn = await dataController.isReadingInsightsOn
        let isEditingInsightsOn = await dataController.isEditingInsightsOn
        let isAllTimeImpactOn = await dataController.isAllTimeImpactOn
        let isLastInAppDonationOn = await dataController.isLastInAppDonationOn
        let isTimelineOfBehaviorOn = await dataController.isTimelineOfBehaviorOn
        
        self.isTimeSpentReadingOn = isTimeSpentReadingOn
        self.isReadingInsightsOn = isReadingInsightsOn
        self.isEditingInsightsOn = isEditingInsightsOn
        self.isAllTimeImpactOn = isAllTimeImpactOn
        self.isLastInAppDonationOn = isLastInAppDonationOn
        self.isTimelineOfBehaviorOn = isTimelineOfBehaviorOn
    }
    
    private func bindPublishedProperties() {
        $isTimeSpentReadingOn
            .sink { [weak self] value in
                guard let self else { return }
                Task {
                    await self.dataController.updateIsTimeSpentReadingOn(value)
                }
                
            }
            .store(in: &cancellables)

        $isReadingInsightsOn
            .sink { [weak self] value in
                guard let self else { return }
                Task {
                    await self.dataController.updateIsReadingInsightsOn(value)
                }
                
            }
            .store(in: &cancellables)

        $isEditingInsightsOn
            .sink { [weak self] value in
                guard let self else { return }
                Task {
                    await self.dataController.updateIsEditingInsightsOn(value)
                }
                
            }
            .store(in: &cancellables)
        
        $isAllTimeImpactOn
            .sink { [weak self] value in
                guard let self else { return }
                Task {
                    await self.dataController.updateIsAllTimeImpactOn(value)
                }
                
            }
            .store(in: &cancellables)
        
        $isLastInAppDonationOn
            .sink { [weak self] value in
                guard let self else { return }
                Task {
                    await self.dataController.updateIsLastInAppDonationOn(value)
                }
                
            }
            .store(in: &cancellables)
        
        $isTimelineOfBehaviorOn
            .sink { [weak self] value in
                guard let self else { return }
                Task {
                    await self.dataController.updateIsTimelineOfBehaviorOn(value)
                }
                
            }
            .store(in: &cancellables)
    }

    public struct LocalizedStrings {
        let timeSpentReading: String
        let readingInsights: String
        let editingInsights: String
        let allTimeImpact: String
        let lastInAppDonation: String
        let timeline: String
        let footer: String

        public init(timeSpentReading: String, readingInsights: String, editingInsights: String, allTimeImpact: String, lastInAppDonation: String, timeline: String, footer: String) {
            self.timeSpentReading = timeSpentReading
            self.readingInsights = readingInsights
            self.editingInsights = editingInsights
            self.allTimeImpact = allTimeImpact
            self.lastInAppDonation = lastInAppDonation
            self.timeline = timeline
            self.footer = footer
        }
    }
}
