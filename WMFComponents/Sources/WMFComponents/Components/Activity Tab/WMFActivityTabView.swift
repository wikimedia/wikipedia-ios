import SwiftUI
import WMFData
import Charts
import Foundation

public struct WMFActivityTabView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject public var viewModel: WMFActivityTabViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public init(viewModel: WMFActivityTabViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
                List {
                    ForEach(viewModel.timelineSections, id: \.self) { section in
                        timelineSection(section: section)
                            .listRowSeparator(.hidden)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.grouped)
                .background(Color(uiColor: theme.paperBackground).edgesIgnoringSafeArea(.all))
                .onAppear {
                    // Only fetch once
                    Task {
                        if viewModel.timelineSections.isEmpty {
                            await viewModel.initialFetch()
                        } else {
                            await viewModel.refreshData()
                        }
                    }
                    viewModel.hasSeenActivityTab()
                }
        }
    }
    
    private func timelineSection(section: TimelineSection) -> some View {
        let calendar = Calendar.current

        let title: String
        let subtitle: String
        if calendar.isDateInToday(section.date) {
            title = viewModel.localizedStrings.todayTitle
            subtitle = viewModel.formatDate(section.date)
        } else if calendar.isDateInYesterday(section.date) {
            title = viewModel.localizedStrings.yesterdayTitle
            subtitle = viewModel.formatDate(section.date)
        } else {
            title = viewModel.formatDate(section.date)
            subtitle = ""
        }

        return Section(
            header:
                VStack(alignment: .leading, spacing: 4) {
                    if !title.isEmpty {
                        Text(title)
                            .font(Font(WMFFont.for(.boldTitle3)))
                            .foregroundColor(Color(uiColor: theme.text))
                            .textCase(.none)
                    }
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundColor(Color(uiColor: theme.secondaryText))
                            .textCase(.none)
                    }
                }
                .padding(.bottom, 20)
        ) {
            ForEach(section.items, id: \.self) { item in
                itemRow(item: item, sectionDate: section.date)
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        let itemToDelete = section.items[index]
                        await viewModel.deleteItem(item: itemToDelete, in: section)
                    }
                }
            }
        }
    }
    
    private func itemRow(item: TimelineItem, sectionDate: Date) -> some View {
        let iconImage: UIImage? = WMFSFSymbolIcon.for(symbol: .textPage, font: .callout)

        let pageRowViewModel = WMFAsyncPageRowViewModel(wmfpage: item.pageWithTimestamp.page, titleHtml:  item.pageWithTimestamp.page.title.replacingOccurrences(of: "_", with: " "), iconImage: iconImage)

        return WMFAsyncPageRow(viewModel: pageRowViewModel)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.onTap(item)
        }
        .contextMenu {
            Button {
                viewModel.onTap(item)
            } label: {
                HStack {
                    Text(viewModel.localizedStrings.openArticle)
                        .font(Font(WMFFont.for(.mediumSubheadline)))
                    Spacer()
                    if let icon = WMFSFSymbolIcon.for(symbol: .chevronForward, font: .mediumSubheadline) {
                        Image(uiImage: icon)
                    }
                }
            }
        }
    }
}
