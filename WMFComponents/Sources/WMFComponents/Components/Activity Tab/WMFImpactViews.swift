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
    
    var body: some View {
        VStack(spacing: 16) {
            if let allTimeImpactViewModel {
                AllTimeImpactView(viewModel: allTimeImpactViewModel)
                
                Divider()
                    .frame(height: 1)
                    .overlay(
                        Rectangle()
                            .fill(Color(uiColor: theme.baseBackground))
                            .frame(height: 1)
                    )
                    .padding(0)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CombinedImpactTitleView(text: "All time impact")

            VStack(spacing: 16) {
                
                if isCompactAndAccessible {
                    impactMetric(
                        icon: WMFSFSymbolIcon.for(symbol: .pencil, font: .title2),
                        value: "\(viewModel.totalEdits ?? 0)",
                        label: "total edits"
                    )
                    impactMetric(
                        icon: WMFSFSymbolIcon.for(symbol: .starCircleFill, font: .title2),
                        value: "\(viewModel.bestStreak ?? 0)",
                        label: "best streak"
                    )
                    impactMetric(
                        icon: WMFIcon.thankFill,
                        value: "\(viewModel.thanksCount ?? 0)",
                        label: "thanks"
                    )
                    impactMetric(
                        icon: WMFIcon.editHistory,
                        value: formatLastEdited(viewModel.lastEdited),
                        label: "last edited"
                    )
                } else {
                    HStack(spacing: 8) {
                        
                        impactMetric(
                            icon: WMFSFSymbolIcon.for(symbol: .pencil, font: .title2),
                            value: "\(viewModel.totalEdits ?? 0)",
                            label: "total edits"
                        )
                        
                        impactMetric(
                            icon: WMFSFSymbolIcon.for(symbol: .starCircleFill, font: .title2),
                            value: "\(viewModel.bestStreak ?? 0)",
                            label: "best streak"
                        )
                    }

                    HStack(spacing: 8) {
                        
                        impactMetric(
                            icon: WMFIcon.thankFill,
                            value: "\(viewModel.thanksCount ?? 0)",
                            label: "thanks"
                        )
                        
                        impactMetric(
                            icon: WMFIcon.editHistory,
                            value: formatLastEdited(viewModel.lastEdited),
                            label: "last edited"
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

    @ViewBuilder
    private func impactMetric(icon: UIImage?, value: String, label: String) -> some View {
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
    }
}


struct RecentActivityView: View {
    let viewModel: RecentActivityViewModel

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CombinedImpactTitleView(text: "Your recent activity (last 30 days)")

            VStack(alignment: .leading, spacing: 0) {
                Text("\(viewModel.editCount)")
                    .font(Font(WMFFont.for(.boldTitle1)))
                    .foregroundStyle(Color(theme.text))

                Text("edits")
                    .font(Font(WMFFont.for(.boldCaption1)))
                    .foregroundStyle(Color(theme.secondaryText))

                if !viewModel.edits.isEmpty {
                    EditActivityGrid(edits: viewModel.edits, theme: theme)
                        .padding(.vertical, 8)
                }

                HStack {
                    Text(DateFormatter.monthDayFormatter.string(from: viewModel.startDate))
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(Color(theme.secondaryText))

                    Spacer()

                    Text(DateFormatter.monthDayFormatter.string(from: viewModel.endDate))
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(Color(theme.secondaryText))
                }
            }
        }
    }

    private struct EditActivityGrid: View {
        let edits: [RecentActivityViewModel.Edit]
        let theme: WMFTheme

        var body: some View {
            GeometryReader { geometry in
                let spacing: CGFloat = 1.5
                let squareCount = 30
                let totalSpacing = spacing * CGFloat(squareCount - 1)
                let squareSize = (geometry.size.width - totalSpacing) / CGFloat(squareCount)

                HStack(spacing: spacing) {
                    ForEach(0..<30, id: \.self) { index in
                        let hasEdits = index < edits.count && edits[index].count > 0

                        Rectangle()
                            .fill(hasEdits ? Color(theme.link) : Color(theme.baseBackground))
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
            CombinedImpactTitleView(text: "Views on articles you've edited")

            VStack(alignment: .leading, spacing: 12) {
                    Text(formatViewCount(viewModel.views.reduce(0) { $0 + $1.count }))
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundStyle(Color(theme.text))

                    if !viewModel.views.isEmpty {
                        LineChartView(data: viewModel.views.map { $0.count })
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

        @ObservedObject var appEnvironment = WMFAppEnvironment.current

        var theme: WMFTheme {
            return appEnvironment.theme
        }

        var body: some View {
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    LineMark(
                        x: .value("Day", index),
                        y: .value("Views", data[index])
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
    let title: String

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var body: some View {
        Text(title)
            .foregroundStyle(Color(theme.text))
            .font(Font(WMFFont.for(.boldCaption1)))
            .padding(.horizontal, 16)
            .accessibilityAddTraits(.isHeader)
    }
}
