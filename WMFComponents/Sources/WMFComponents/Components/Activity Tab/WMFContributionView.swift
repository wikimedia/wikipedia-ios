import SwiftUI
import WMFData
import Charts
import Foundation

struct ContributionsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    let viewModel: ContributionsViewModel
    
    var fullWidth: Int {
        max(viewModel.lastMonthCount, viewModel.thisMonthCount)
    }
    
    var body: some View {
        WMFActivityTabInfoCardView(
            icon: WMFIcon.contributionsIcon,
            title: viewModel.activityViewModel.localizedStrings.contributionsThisMonth,
            dateText: viewModel.dateText,
            additionalAccessibilityLabel: nil,
            onTapModule: viewModel.activityViewModel.navigateToContributions,
            content: {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(viewModel.thisMonthCount))
                            .font(Font(WMFFont.for(.boldTitle1)))
                            .foregroundStyle(Color(uiColor: theme.text))
                        Text(viewModel.activityViewModel.localizedStrings.thisMonth)
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
                        Text(viewModel.activityViewModel.localizedStrings.lastMonth)
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
            }, showArrowAnyways: true
        )
        .frame(maxWidth: .infinity, alignment: .leading)
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
