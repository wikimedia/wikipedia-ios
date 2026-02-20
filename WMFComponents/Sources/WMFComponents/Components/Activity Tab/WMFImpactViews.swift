import SwiftUI
import WMFData
import Charts
import Foundation

struct CombinedImpactView: View {
    let allTimeImpactViewModel: AllTimeImpactViewModel?
    let recentActivityViewModel: RecentActivityViewModel?
    let articleViewsViewModel: ArticleViewsViewModel?
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var needsAllTimeDiv: Bool {
        return recentActivityViewModel != nil || articleViewsViewModel != nil
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let allTimeImpactViewModel {
                AllTimeImpactView(viewModel: allTimeImpactViewModel)
                
                if needsAllTimeDiv {
                    Divider()
                        .frame(height: 1)
                        .overlay(
                            Rectangle()
                                .fill(Color(uiColor: theme.baseBackground))
                                .frame(height: 1)
                        )
                        .padding(0)
                }
                
            }
            
            if let recentActivityViewModel {
                RecentActivityView(viewModel: recentActivityViewModel)
                
                Divider()
                    .frame(height: 1)
                    .overlay(
                        Rectangle()
                            .fill(Color(uiColor: theme.baseBackground))
                            .frame(height: 1)
                    )
                    .padding(0)
            }
            
            if let articleViewsViewModel {
                ArticleViewsView(viewModel: articleViewsViewModel)
            }
        }
        .padding(16)
        .background(Color(theme.paperBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(theme.baseBackground), lineWidth: 0.5)
        )
    }
}

private struct CombinedImpactTitleView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let text: String

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        Text(text)
            .foregroundStyle(Color(theme.text))
            .font(Font(WMFFont.for(.boldCaption1)))
            .multilineTextAlignment(.leading)
            .lineLimit(4)
            .accessibilityAddTraits(.isHeader)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct AllTimeImpactView: View {
    let viewModel: AllTimeImpactViewModel

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.sizeCategory) var sizeCategory

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var isCompactAndAccessible: Bool {
        horizontalSizeClass == .compact && sizeCategory >= .extraExtraLarge
    }
    
    var totalEditsValue: String {
        if let totalEdits = viewModel.totalEdits {
            return "\(totalEdits)"
        }
        
        return "0"
    }
    
    var bestStreakValue: String {
        if let bestStreak = viewModel.bestStreak {
            return viewModel.localizedStrings.bestStreakValue(bestStreak)
        }
        
        return "-"
    }
    
    var thanksValue: String {
        if let thanks = viewModel.thanksCount {
            return "\(thanks)"
        }
        
        return "0"
    }
    
    var lastEditedValue: String {
        if let lastEdited = viewModel.lastEdited {
            return formatLastEdited(lastEdited)
        }
        
        return "-"
    }
    
    var lastEditedAccessibilityValue: String {
        if let lastEdited = viewModel.lastEdited {
            return formatLastEditedForAccessibility(lastEdited)
        }
        
        return "-"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CombinedImpactTitleView(text: viewModel.localizedStrings.allTimeImpact)

            VStack(spacing: 16) {
                
                if isCompactAndAccessible {
                    impactMetric(
                        icon: WMFSFSymbolIcon.for(symbol: .pencil, font: .title2),
                        value: totalEditsValue,
                        label: viewModel.localizedStrings.totalEdits
                    )
                    impactMetric(
                        icon: WMFSFSymbolIcon.for(symbol: .starCircleFill, font: .title2),
                        value: bestStreakValue,
                        label: viewModel.localizedStrings.bestStreakLabel
                    )
                    impactMetric(
                        icon: WMFIcon.thankFill,
                        value: thanksValue,
                        label: viewModel.localizedStrings.thanks
                    )
                    impactMetric(
                        icon: WMFIcon.editHistory,
                        value: lastEditedValue,
                        label: viewModel.localizedStrings.lastEdited,
                        customAccessibilityValue: lastEditedAccessibilityValue
                    )
                } else {
                    HStack(spacing: 8) {
                        
                        impactMetric(
                            icon: WMFSFSymbolIcon.for(symbol: .pencil, font: .title2),
                            value: totalEditsValue,
                            label: viewModel.localizedStrings.totalEdits
                        )
                        
                        impactMetric(
                            icon: WMFSFSymbolIcon.for(symbol: .starCircleFill, font: .title2),
                            value: bestStreakValue,
                            label: viewModel.localizedStrings.bestStreakLabel
                        )
                    }

                    HStack(spacing: 8) {
                        
                        impactMetric(
                            icon: WMFIcon.thankFill,
                            value: thanksValue,
                            label: viewModel.localizedStrings.thanks
                        )
                        
                        impactMetric(
                            icon: WMFIcon.editHistory,
                            value: lastEditedValue,
                            label: viewModel.localizedStrings.lastEdited,
                            customAccessibilityValue: lastEditedAccessibilityValue
                        )
                    }
                }
            }
        }
    }
    
    private func formatLastEdited(_ date: Date?) -> String {
        guard let date else { return "-" }
        return DateFormatter.lastEditedDateFormatter.string(from: date)
    }
    
    private func formatLastEditedForAccessibility(_ date: Date?) -> String {
        guard let date else { return "" }
        return DateFormatter.wmfMonthDayYearDateFormatter.string(from: date)
    }

    @ViewBuilder
    private func impactMetric(icon: UIImage?, value: String, label: String, customAccessibilityValue: String? = nil) -> some View {
        HStack(spacing: 12) {
            if let icon {
                Image(uiImage: icon)
                    .foregroundStyle(Color(theme.link))
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(Font(WMFFont.for(.boldCallout)))
                    .foregroundStyle(Color(theme.text))

                Text(label)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.secondaryText))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement()
        .accessibilityLabel(label + ", " + (customAccessibilityValue ?? value))
    }
}


struct RecentActivityView: View {
    let viewModel: RecentActivityViewModel

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var startDateString: String {
        return DateFormatter.monthDayFormatter.string(from: viewModel.startDate)
    }
    
    var endDateString: String {
        return DateFormatter.monthDayFormatter.string(from: viewModel.endDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CombinedImpactTitleView(text: viewModel.localizedStrings.yourRecentActivity)

            VStack(alignment: .leading, spacing: 0) {
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(viewModel.editCount)")
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundStyle(Color(theme.text))

                    Text(viewModel.localizedStrings.edits)
                        .font(Font(WMFFont.for(.boldCaption1)))
                        .foregroundStyle(Color(theme.secondaryText))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(viewModel.editCount)" + viewModel.localizedStrings.edits)

                if !viewModel.edits.isEmpty {
                    EditActivityGrid(edits: viewModel.edits, theme: theme)
                        .padding(.vertical, 8)
                }

                HStack {
                    Text(startDateString)
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(Color(theme.secondaryText))

                    Spacer()

                    Text(endDateString)
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(Color(theme.secondaryText))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(viewModel.localizedStrings.startEndDatesAccessibilityLabel(startDateString, endDateString))
            }
            
        }
    }

    private struct EditActivityGrid: View {
        let edits: [RecentActivityViewModel.Edit]
        let theme: WMFTheme

        var body: some View {
            GeometryReader { geometry in
                let spacing: CGFloat = 1.5
                let squareCount = edits.count
                let totalSpacing = spacing * CGFloat(squareCount - 1)
                let squareSize = (geometry.size.width - totalSpacing) / CGFloat(squareCount)

                HStack(spacing: spacing) {
                    ForEach(edits) { edit in
                        Rectangle()
                            .fill(edit.count > 0 ? Color(theme.link) : Color(theme.newBorder))
                            .frame(width: squareSize, height: 24)
                    }
                }
            }
            .frame(height: 24)
        }
    }
}

struct ArticleViewsView: View {
    let viewModel: ArticleViewsViewModel

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CombinedImpactTitleView(text: viewModel.localizedStrings.viewsOnArticlesYouveEdited)

            VStack(alignment: .leading, spacing: 12) {
                    Text(formatViewCount(viewModel.views.reduce(0) { $0 + $1.count }))
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundStyle(Color(theme.text))

                    if !viewModel.views.isEmpty {
                        LineChartView(data: viewModel.views.map { $0.count }, xLabel: viewModel.localizedStrings.lineGraphDay, yLabel: viewModel.localizedStrings.lineGraphViews)
                            .frame(height: 15)
                    }
                }
        }
    }

    private func formatViewCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
    
    struct LineChartView: View {
        let data: [Int]
        let xLabel: String
        let yLabel: String

        @ObservedObject var appEnvironment = WMFAppEnvironment.current

        var theme: WMFTheme {
            return appEnvironment.theme
        }

        var body: some View {
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    LineMark(
                        x: .value(xLabel, index),
                        y: .value(yLabel, data[index])
                    )
                    .foregroundStyle(Color(theme.link))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        }
    }
}

struct YourImpactHeaderView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFActivityTabViewModel
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.localizedStrings.yourImpact)
                .font(Font(WMFFont.for(.boldHeadline)))
                .foregroundColor(Color(uiColor: theme.text))
                .textCase(.none)
                .accessibilityAddTraits(.isHeader)
            
            if let subtitle = viewModel.yourImpactOnWikipediaSubtitle {
                Text(subtitle)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                    .textCase(.none)
            }
            
        }
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
}
