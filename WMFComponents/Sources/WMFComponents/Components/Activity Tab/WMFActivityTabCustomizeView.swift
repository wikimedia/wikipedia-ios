import SwiftUI
import Foundation
import WMFData

public struct WMFActivityTabCustomizeView: View {
    @ObservedObject private var viewModel: WMFActivityTabCustomizeViewModel
    
    public init(viewModel: WMFActivityTabCustomizeViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Form {
            Toggle(
                viewModel.localizedStrings.timeSpentReading,
                isOn: $viewModel.isTimeSpentReadingOn
            )
            
            Toggle(
                viewModel.localizedStrings.readingInsights,
                isOn: $viewModel.isReadingInsightsOn
            )
            
            Toggle(
                viewModel.localizedStrings.editingInsights,
                isOn: $viewModel.isEditingInsightsOn
            )
            
            Toggle(
                viewModel.localizedStrings.allTimeImpact,
                isOn: $viewModel.isAllTimeImpactOn
            )
            
            Toggle(
                viewModel.localizedStrings.lastInAppDonation,
                isOn: $viewModel.isLastInAppDonationOn
            )
            
            Toggle(
                viewModel.localizedStrings.timeline,
                isOn: $viewModel.isTimelineOfBehaviorOn
            )
        }
    }
}
