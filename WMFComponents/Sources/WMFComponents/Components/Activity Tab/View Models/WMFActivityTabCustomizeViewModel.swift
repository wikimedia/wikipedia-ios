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
    var isLoggedIn: Bool {
        didSet {
            Task {
               await updateFromDataController()
            }
        }
    }
    var presentLoggedInToastAction: (() -> Void)?
    
    private let dataController = WMFActivityTabDataController.shared
    
    private var cancellables = Set<AnyCancellable>()

    public init(localizedStrings: LocalizedStrings, isLoggedIn: Bool) {
        self.localizedStrings = localizedStrings 
        self.isLoggedIn = isLoggedIn
        self.presentLoggedInToastAction = nil
        
        Task {
            await updateFromDataController()
            bindPublishedProperties()
        }
    }
    
    private func updateFromDataController() async {
        let isTimeSpentReadingOn = isLoggedIn ? await dataController.isTimeSpentReadingOn : false
        let isReadingInsightsOn = isLoggedIn ? await dataController.isReadingInsightsOn : false
        let isEditingInsightsOn = isLoggedIn ?  await dataController.isEditingInsightsOn : false
        let isAllTimeImpactOn = isLoggedIn ? await dataController.isAllTimeImpactOn : false
        let isLastInAppDonationOn = isLoggedIn ? await dataController.isLastInAppDonationOn : false
        let isTimelineOfBehaviorOn: Bool
        
        if isLoggedIn {
            isTimelineOfBehaviorOn = await dataController.isTimelineOfBehaviorOnLoggedIn
        } else {
            isTimelineOfBehaviorOn = await dataController.isTimelineOfBehaviorOnLoggedOut
        }
        
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
                guard let self, self.isLoggedIn else { return }
                
                Task {
                    await self.dataController.updateIsTimeSpentReadingOn(value)
                }
                
            }
            .store(in: &cancellables)

        $isReadingInsightsOn
            .sink { [weak self] value in
                guard let self, self.isLoggedIn else { return }
                
                Task {
                    await self.dataController.updateIsReadingInsightsOn(value)
                }
                
            }
            .store(in: &cancellables)

        $isEditingInsightsOn
            .sink { [weak self] value in
                guard let self, self.isLoggedIn else { return }
                
                Task {
                    await self.dataController.updateIsEditingInsightsOn(value)
                }
                
            }
            .store(in: &cancellables)
        
        $isAllTimeImpactOn
            .sink { [weak self] value in
                guard let self, self.isLoggedIn else { return }
                
                Task {
                    await self.dataController.updateIsAllTimeImpactOn(value)
                }
                
            }
            .store(in: &cancellables)
        
        $isLastInAppDonationOn
            .sink { [weak self] value in
                guard let self, self.isLoggedIn else { return }
                
                Task {
                    await self.dataController.updateIsLastInAppDonationOn(value)
                }
                
            }
            .store(in: &cancellables)
        
        $isTimelineOfBehaviorOn
            .sink { [weak self] value in
                guard let self else { return }
                Task {
                    if self.isLoggedIn {
                        await self.dataController.updateIsTimelineOfBehaviorOnLoggedIn(value)
                    } else {
                        await self.dataController.updateIsTimelineOfBehaviorOnLoggedOut(value)
                    }
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
