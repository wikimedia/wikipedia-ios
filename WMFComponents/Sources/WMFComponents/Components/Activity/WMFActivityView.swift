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
                WMFHtmlText(html: viewModel.localizedStrings.getGreeting(), styles: titleStyles)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                if let editActivityItem = viewModel.editActivityItem {
                    WMFActivityComponentView(
                        activityItem: editActivityItem,
                        title: viewModel.title(for: editActivityItem.type),
                        onButtonTap: viewModel.action(for: editActivityItem.type),
                        buttonTitle: viewModel.localizedStrings.viewEdited,
                        backgroundColor: viewModel.backgroundColor(for: editActivityItem.type),
                        leadingIconColor: viewModel.leadingIconColor(for: editActivityItem.type),
                        leadingIconName: editActivityItem.imageName,
                        trailingIconName: viewModel.trailingIconName(for: editActivityItem.type),
                        titleFont: viewModel.titleFont(for: editActivityItem.type))
                    .padding(.vertical, 8)
                }

                if let readActivityItem = viewModel.readActivityItem {
                    WMFActivityComponentView(
                        activityItem: readActivityItem,
                        title: viewModel.title(for: readActivityItem.type),
                        onButtonTap: viewModel.action(for: readActivityItem.type),
                        buttonTitle: viewModel.localizedStrings.viewHistory,
                        backgroundColor: viewModel.backgroundColor(for: readActivityItem.type),
                        leadingIconColor: viewModel.leadingIconColor(for: readActivityItem.type),
                        leadingIconName: readActivityItem.imageName,
                        trailingIconName: viewModel.trailingIconName(for: readActivityItem.type),
                        titleFont: viewModel.titleFont(for: readActivityItem.type))
                    .padding(.vertical, 8)
                }

                if let savedActivityItem = viewModel.savedActivityItem {
                    WMFActivityComponentView(
                        activityItem: savedActivityItem,
                        title: viewModel.title(for: savedActivityItem.type),
                        onButtonTap: viewModel.action(for: savedActivityItem.type),
                        buttonTitle: viewModel.localizedStrings.viewSaved,
                        backgroundColor: viewModel.backgroundColor(for: savedActivityItem.type),
                        leadingIconColor: viewModel.leadingIconColor(for: savedActivityItem.type),
                        leadingIconName: savedActivityItem.imageName,
                        trailingIconName: viewModel.trailingIconName(for: savedActivityItem.type),
                        titleFont: viewModel.titleFont(for: savedActivityItem.type))
                    .padding(.vertical, 8)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .onAppear {
                Task {
                    guard let project = viewModel.project,
                          let username = viewModel.username else { return }

                    let dataController = try WMFActivityDataController()
                    dataController.savedSlideDataDelegate = viewModel.savedSlideDataDelegate
                    dataController.legacyPageViewsDataDelegate = viewModel.legacyPageViewsDataDelegate
                    let activity = try await dataController.fetchAllStuff(username: username, project: project)

                    var editsItem = ActivityItem(type: .noEdit)
                    if let editedCount = activity.editedCount, editedCount > 0 {
                        editsItem = ActivityItem(type: .edit(editedCount))
                    }

                    viewModel.editActivityItem = editsItem
                    viewModel.readActivityItem = ActivityItem(type: .read(activity.readCount))
                    viewModel.savedActivityItem = ActivityItem(type: .save(activity.savedCount))
                }
            }
            .background(Color(theme.paperBackground))
        } else {
            if let loginAction = viewModel.loginAction {
                WMFActivityTabLoggedOutView(viewModel: viewModel, loginAction: loginAction, openHistory: viewModel.openHistoryLoggedOut)
            }
        }
    }

}
