import SwiftUI
import WMFData
import Charts
import Foundation

public struct ContributionsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    let viewModel: ContributionsViewModel
    let activityViewModel: WMFActivityTabViewModel
    
    var fullWidth: Int {
        max(viewModel.lastMonthCount, viewModel.thisMonthCount)
    }
    
    public var body: some View {
        WMFActivityTabInfoCardView(
            icon:
                (UIImage(named: "user_contributions", in: .module, with: nil)),
            title: activityViewModel.localizedStrings.contributionsThisMonth,
            dateText: dateText,
            additionalAccessibilityLabel: nil,
            onTapModule: activityViewModel.navigateToContributions,
            content: {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(viewModel.thisMonthCount))
                            .font(Font(WMFFont.for(.boldTitle1)))
                            .foregroundStyle(Color(uiColor: theme.text))
                        Text(activityViewModel.localizedStrings.thisMonth)
                            .font(Font(WMFFont.for(.boldCaption1)))
                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                        if viewModel.thisMonthCount > 0 {
                            ContributionBar(
                                count: viewModel.thisMonthCount,
                                maxCount: fullWidth,
                                color: theme.accent
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(viewModel.lastMonthCount))
                            .font(Font(WMFFont.for(.boldTitle1)))
                            .foregroundStyle(Color(uiColor: theme.text))
                        Text(activityViewModel.localizedStrings.lastMonth)
                            .font(Font(WMFFont.for(.boldCaption1)))
                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                        if viewModel.lastMonthCount > 0 {
                            ContributionBar(
                                count: viewModel.lastMonthCount,
                                maxCount: fullWidth,
                                color: theme.baseBackground
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var dateText: String {
        guard let lastEdited = viewModel.lastEdited else { return ""}
        let calendar = Calendar.current

        let title: String
        if calendar.isDateInToday(lastEdited) {
            title = activityViewModel.localizedStrings.todayTitle
        } else if calendar.isDateInYesterday(lastEdited) {
            title = activityViewModel.localizedStrings.yesterdayTitle
        } else {
            title = activityViewModel.formatDate(lastEdited)
        }
        
        return title
    }
}

private struct ContributionBar: View {
    let count: Int
    let maxCount: Int
    let color: UIColor

    var body: some View {
        GeometryReader { geometry in
            let ratio = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0

            Rectangle()
                .fill(Color(uiColor: color))
                .frame(width: geometry.size.width * ratio)
        }
        .frame(height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
