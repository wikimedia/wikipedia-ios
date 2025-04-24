import SwiftUI
import WMFData

public struct WMFActivityView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WMFActivityViewModel

    public init(viewModel: WMFActivityViewModel) {
        self.viewModel = viewModel
    }
    
    private var titleStyles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WMFFont.for(.title3), boldFont: WMFFont.for(.boldTitle3), italicsFont: WMFFont.for(.italicGeorgiaTitle3), boldItalicsFont: WMFFont.for(.boldItalicGeorgiaTitle3), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    public var body: some View {

        if viewModel.isLoggedIn {
            VStack(alignment: .leading) {
                WMFHtmlText(html: viewModel.localizedStrings.greeting, styles: titleStyles)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                if viewModel.hasNoEdits {
                    noEditsView
                        .padding(.vertical, 8)
                } else if viewModel.shouldShowAddAnImage {
                    Text(viewModel.suggestedEdits)
                    suggestedEditsView // TODO: add editing activity item a bove
                }
                if let activityItems = viewModel.activityItems {
                    ForEach(activityItems, id: \.title) { item in
                        if item.type != .noEdit {
                            WMFActivityComponentView(
                                activityItem: item,
                                title: viewModel.title(for: item.type),
                                onButtonTap: viewModel.action(for: item.type),
                                shouldDisplayButton: true,
                                backgroundColor: viewModel.backgroundColor(for: item.type),
                                iconColor: viewModel.iconColor(for: item.type),
                                borderColor: viewModel.borderColor(for: item.type),
                                iconName: item.imageName)
                            .padding(.vertical, 8)
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .onAppear {
                Task {
                    guard let project = viewModel.project else { return }
                    
                    let dataController = try WMFActivityDataController()
                    dataController.savedSlideDataDelegate = viewModel.savedSlideDataDelegate
                    dataController.legacyPageViewsDataDelegate = viewModel.legacyPageViewsDataDelegate
                    let activity = try await dataController.fetchAllStuff(username: "TSevener (WMF)", project: project)
                    var testItems = [
                        ActivityItem(title: "You saved \(activity.savedCount) articles this week", subtitle: nil, type: .save),
                        ActivityItem(title: "You read \(activity.readCount) articles this week.", subtitle: nil, type: .read)
                    ]

                    if !viewModel.hasNoEdits {
                        let editsItem = ActivityItem(title: "You edited \(activity.editedCount ?? 0) article(s) this week.", subtitle: nil, type: .edit)
                            testItems.insert(editsItem, at: 0)
                    }

                    viewModel.activityItems = testItems
                }
            }
        } else {
            if let loginAction = viewModel.loginAction {
                WMFActivityTabLoggedOutView(loginAction: loginAction, openHistory: viewModel.openHistory)
            }
        }
    }

    private var noEditsView: some View {
        VStack(alignment: .leading) {
            let item = ActivityItem(title: viewModel.localizedStrings.activityTabNoEditsTitle, subtitle: viewModel.localizedStrings.activityTabNoEditsTitle, type: .noEdit)
            // TODO: - get AB testing for `shouldDisplayButton`
            WMFActivityComponentView(
                activityItem: item,
                title: viewModel.title(for: item.type),
                onButtonTap: viewModel.action(for: item.type),
                shouldDisplayButton: true,
                backgroundColor: viewModel.backgroundColor(for: item.type),
                iconColor: viewModel.iconColor(for: item.type),
                borderColor: viewModel.borderColor(for: item.type),
                iconName: item.imageName)
        }
    }

    private var suggestedEditsView: some View {
        HStack(alignment: .center, spacing: 18) {
            Image(systemName: "photo.badge.checkmark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40)
                .foregroundStyle(Color(theme.iconBackground))
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.addAnImageTitle)
                    .font(Font(WMFFont.for(.boldCallout)))
                Text(viewModel.addAnImageSubtitle)
                    .font(Font(WMFFont.for(.callout)))
                Button(action: {
                    viewModel.openSuggestedEdits?()
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "plus")
                        Text(viewModel.addAnImageButtonTitle)
                    }
                    .foregroundColor(Color(uiColor: theme.paperBackground))
                    .font(Font(WMFFont.for(.boldCallout)))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(theme.link))
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(theme.baseBackground))
        .border(Color(theme.iconBackground), width: 2)
    }
}
