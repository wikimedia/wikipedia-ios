import WMFData
import SwiftUI

@MainActor
public final class WMFActivityTabCustomizeViewModel: ObservableObject {
    public let customization: Binding<WMFActivityTabViewModel.ActivityTabCustomization>
    let localizedStrings: LocalizedStrings

    func updatedCustomization() -> WMFActivityTabViewModel.ActivityTabCustomization {
        customization.wrappedValue
    }

    public var toggleMappings: [(label: String, binding: Binding<Bool>)] {
        [
            (
                localizedStrings.timeSpentReading,
                Binding(
                    get: { self.customization.wrappedValue.isTimeSpentReadingOn },
                    set: { self.customization.wrappedValue.isTimeSpentReadingOn = $0 }
                )
            ),
            (
                localizedStrings.readingInsights,
                Binding(
                    get: { self.customization.wrappedValue.isReadingInsightsOn },
                    set: { self.customization.wrappedValue.isReadingInsightsOn = $0 }
                )
            ),
            (
                localizedStrings.editingInsights,
                Binding(
                    get: { self.customization.wrappedValue.isEditingInsightsOn },
                    set: { self.customization.wrappedValue.isEditingInsightsOn = $0 }
                )
            ),
            (
                localizedStrings.allTimeImpact,
                Binding(
                    get: { self.customization.wrappedValue.isAllTimeImpactOn },
                    set: { self.customization.wrappedValue.isAllTimeImpactOn = $0 }
                )
            ),
            (
                localizedStrings.lastInAppDonation,
                Binding(
                    get: { self.customization.wrappedValue.isLastInAppDonationOn },
                    set: { self.customization.wrappedValue.isLastInAppDonationOn = $0 }
                )
            ),
            (
                localizedStrings.timeline,
                Binding(
                    get: { self.customization.wrappedValue.isTimelineOfBehaviorOn },
                    set: { self.customization.wrappedValue.isTimelineOfBehaviorOn = $0 }
                )
            )
        ]
    }

    public init(
        customization: Binding<WMFActivityTabViewModel.ActivityTabCustomization>,
        localizedStrings: LocalizedStrings
    ) {
        self.customization = customization
        self.localizedStrings = localizedStrings
    }

    public struct LocalizedStrings {
        let timeSpentReading: String
        let readingInsights: String
        let editingInsights: String
        let allTimeImpact: String
        let lastInAppDonation: String
        let timeline: String

        public init(
            timeSpentReading: String,
            readingInsights: String,
            editingInsights: String,
            allTimeImpact: String,
            lastInAppDonation: String,
            timeline: String
        ) {
            self.timeSpentReading = timeSpentReading
            self.readingInsights = readingInsights
            self.editingInsights = editingInsights
            self.allTimeImpact = allTimeImpact
            self.lastInAppDonation = lastInAppDonation
            self.timeline = timeline
        }
    }
}
