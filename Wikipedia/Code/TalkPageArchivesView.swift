import SwiftUI

struct TalkPageArchivesItem {
    let title: String
    let displayTitle: String
    let pageID: Int
    
    init?(title: String?, displayTitle: String?, pageID: Int?) {
        guard let title = title,
              let displayTitle = displayTitle,
            let pageID = pageID else {
            return nil
        }
        
        self.title = title
        self.displayTitle = displayTitle
        self.pageID = pageID
    }
}

// TODO: Generalize more
struct TalkPageArchivesButton: View {
    
    let action: (TalkPageArchivesItem) -> Void
    let item: TalkPageArchivesItem
    @EnvironmentObject var observableTheme: ObservableTheme
    
    var body: some View {
        Button(action: { action(item) }) {
            VStack(spacing: 0) {
                HStack {
                    Text(item.displayTitle)
                        .foregroundColor(Color(observableTheme.theme.colors.primaryText))
                        .font(.callout)
                        .fontWeight(.semibold)
                    Spacer(minLength: 12)
                    Image(systemName: "chevron.right").font(Font.system(.footnote).weight(.semibold))
                        .foregroundColor(Color(observableTheme.theme.colors.secondaryText))
                }
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                Divider()
                    .frame(height: 1)
                    .background(Color(observableTheme.theme.colors.midBackground))
            }
        }
        .buttonStyle(BackgroundHighlightingButtonStyle())
    }
}

struct BackgroundHighlightingButtonStyle: ButtonStyle {
    
    @EnvironmentObject var observableTheme: ObservableTheme

    func makeBody(configuration: SwiftUI.ButtonStyle.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(observableTheme.theme.colors.midBackground) : Color(observableTheme.theme.colors.paperBackground))
    }

}

struct TalkPageArchivesView: View {
    
    @SwiftUI.State private var task: Task<Void, Never>?
    @SwiftUI.State private var items: [TalkPageArchivesItem] = []
    @SwiftUI.State private var error: Error? = nil
    @EnvironmentObject var data: CustomNavigationViewData
    @EnvironmentObject var observableTheme: ObservableTheme
    
    private let pageTitle: String
    private let siteURL: URL
    private let fetcher = TalkPageArchivesFetcher()
    
    var didTapItem: (TalkPageArchivesItem) -> Void = { _ in }
    
    init(pageTitle: String, siteURL: URL) {
        self.pageTitle = pageTitle
        self.siteURL = siteURL
    }
    
    var body: some View {
        TrackingScrollView(
            axes: [.vertical],
            showsIndicators: true
        ) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(items, id: \.pageID) { item in
                    TalkPageArchivesButton(action: didTapItem, item: item)
                }
            }
            
        }
        .background(Color(observableTheme.theme.colors.paperBackground))
        .onAppear {
            task = Task(priority: .userInitiated) {
                data.isLoading = true
                do {
                    let response = try await fetcher.fetchArchives(pageTitle: pageTitle, siteURL: siteURL)
                    data.isLoading = false
                    self.items = response.query?.pages?.compactMap {  TalkPageArchivesItem(title: $0.title, displayTitle: $0.displaytitle, pageID: $0.pageid) } ?? []
                } catch {
                    data.isLoading = false
                    self.error = error
                }
            }
        }
        .onDisappear {
            task?.cancel()
            task = nil
        }
    }
}
