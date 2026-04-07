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
    
    var title: String {
        viewModel.activityViewModel?.localizedStrings.contributionsThisMonth ?? ""
    }
    
    var dateText: String {
        viewModel.shouldShowEditCTA ? "" : viewModel.dateText
    }
    
    var contentAccessibilityLabel: String {
        var accessibilityLabel: String = ""
        
        if let editsThisMonthText = viewModel.activityViewModel?.localizedStrings.thisMonth,
           !editsThisMonthText.isEmpty {
            accessibilityLabel.append(String(viewModel.thisMonthCount))
            accessibilityLabel.append(editsThisMonthText + ", ")
        }
        
        if let editsLastMonthText = viewModel.activityViewModel?.localizedStrings.lastMonth,
           !editsLastMonthText.isEmpty {
            
            accessibilityLabel.append(String(viewModel.lastMonthCount))
            accessibilityLabel.append(editsLastMonthText + ", ")
        }
        
        return accessibilityLabel
    }
    
    var body: some View {
        WMFActivityTabInfoCardView(
            icon: WMFIcon.contributionsIcon,
            title: title,
            dateText: dateText,
            onTapModule: viewModel.shouldShowEditCTA ? viewModel.activityViewModel?.makeAnEdit : viewModel.activityViewModel?.navigateToContributions,
            content: {
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(viewModel.thisMonthCount))
                                .font(Font(WMFFont.for(.boldTitle1)))
                                .foregroundStyle(Color(uiColor: theme.text))
                            if let thisMonthCount = viewModel.activityViewModel?.localizedStrings.thisMonth {
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
                            if let lastMonthCount = viewModel.activityViewModel?.localizedStrings.lastMonth {
                                Text(lastMonthCount)
                                    .font(Font(WMFFont.for(.boldCaption1)))
                                    .foregroundStyle(Color(uiColor: theme.secondaryText))
                            }
                            if viewModel.lastMonthCount > 0 {
                                ContributionBar(
                                    count: viewModel.lastMonthCount,
                                    maxCount: fullWidth,
                                    color: theme.newBorder
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(contentAccessibilityLabel)
                    .accessibilityAddTraits(.isButton)
                    
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
                                .padding(.horizontal, 24)
                            Text(activityViewModel.localizedStrings.looksLikeYouHaventMadeAnEdit)
                                .font(Font(WMFFont.for(.subheadline)))
                                .foregroundStyle(Color(theme.text))
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            WMFSmallButton(configuration: .init(style: .primary), title: activityViewModel.localizedStrings.makeAnEdit, image: (WMFSFSymbolIcon.for(symbol: .pencil) ?? nil), action: {
                                activityViewModel.makeAnEdit()
                            })
                            .padding(.horizontal, 24)
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
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .frame(height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
