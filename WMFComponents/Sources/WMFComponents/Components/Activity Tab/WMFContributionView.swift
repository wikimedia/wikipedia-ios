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
            title: viewModel.activityViewModel?.localizedStrings.contributionsThisMonth ?? "",
            dateText: viewModel.dateText,
            additionalAccessibilityLabel: nil,
            onTapModule: viewModel.shouldShowEditCTA ? viewModel.activityViewModel?.navigateToContributions : viewModel.activityViewModel?.navigateToContributions,
            content: {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(viewModel.thisMonthCount))
                            .font(Font(WMFFont.for(.boldTitle1)))
                            .foregroundStyle(Color(uiColor: theme.text))
                        if let thisMonthCount = viewModel.activityViewModel?.localizedStrings.contributionsThisMonth {
                            Text(thisMonthCount)
                                .font(Font(WMFFont.for(.boldCaption1)))
                                .foregroundStyle(Color(uiColor: theme.secondaryText))
                        }
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
                        if let lastMonthCount = viewModel.activityViewModel?.localizedStrings.contributionsThisMonth {
                            Text(lastMonthCount)
                                .font(Font(WMFFont.for(.boldCaption1)))
                                .foregroundStyle(Color(uiColor: theme.secondaryText))
                        }
                        if viewModel.lastMonthCount > 0 {
                            ContributionBar(
                                count: viewModel.lastMonthCount,
                                maxCount: fullWidth,
                                color: theme.baseBackground
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let activityViewModel = viewModel.activityViewModel, viewModel.shouldShowEditCTA {
                        VStack(alignment: .center, spacing: 8) {
                            Divider()
                                .background(Color(theme.baseBackground))
                                .padding(.vertical, 8)
                            Text(activityViewModel.localizedStrings.zeroEditsToArticles)
                                .font(Font(WMFFont.for(.semiboldSubheadline)))
                                .foregroundStyle(Color(theme.text))
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                            Text(activityViewModel.localizedStrings.looksLikeYouHaventMadeAnEdit)
                                .font(Font(WMFFont.for(.subheadline)))
                                .foregroundStyle(Color(theme.text))
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                            WMFSmallButton(configuration: .init(style: .primary), title: activityViewModel.localizedStrings.makeAnEdit, image: (WMFSFSymbolIcon.for(symbol: .pencil) ?? nil), action: {
                                activityViewModel.makeAnEdit()
                            })
                            .padding(.vertical, 12)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
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
