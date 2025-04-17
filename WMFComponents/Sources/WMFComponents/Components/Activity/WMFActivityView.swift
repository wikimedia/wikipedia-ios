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

    public var body: some View {

        if viewModel.isLoggedIn {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.hasNoEdits {
                        noEditsView
                        if viewModel.shouldShowStartEditing {
                            startEditingButton
                        } else if viewModel.shouldShowAddAnImage {
                            suggestedEditsView
                        }
                    } else if viewModel.shouldShowAddAnImage {
                        Text(viewModel.suggestedEdits)
                        suggestedEditsView // TODO: add editing activity item a bove
                    }
                    if let activityItems = viewModel.activityItems {
                        ForEach(activityItems, id: \.title) { item in
                            WMFActivityComponentView(activityItem: item, title: viewModel.title(for: item.type), onButtonTap: viewModel.action(for: item.type))
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding()
            .onAppear {
                Task {
                    
                    guard let project = viewModel.project else { return }
                    
                    let dataController = try WMFActivityDataController()
                    dataController.savedSlideDataDelegate = viewModel.savedSlideDataDelegate
                    dataController.legacyPageViewsDataDelegate = viewModel.legacyPageViewsDataDelegate
                    let activity = try await dataController.fetchAllStuff(username: "TSevener (WMF)", project: project)

                    let testItems = [
                        ActivityItem(imageName: "pencil", title: "You edited \(activity.editedCount ?? 0) article(s) this week.", type: .edit),
                        ActivityItem(imageName: "square.text.square", title: "You read \(activity.readCount) articles this week.", type: .read),
                        ActivityItem(imageName: "bookmark.fill", title: "You saved \(activity.savedCount) articles this week", type: .save)
                    ]

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
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.noEditsTitle)
                .font(Font(WMFFont.for(.boldSubheadline)))
            Text(viewModel.noEditsSubtitle)
                .font(Font(WMFFont.for(.subheadline)))
        }
    }

    private var startEditingButton: some View {
        Button(viewModel.noEditsButtonTitle) {
            print("Start editing")
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
