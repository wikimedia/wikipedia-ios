import SwiftUI
import WMFData

public struct WMFActivityView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WMFActivityViewModel

    let isLoggedIn: Bool

    public init(viewModel: WMFActivityViewModel, isLoggedIn: Bool) {
        self.viewModel = viewModel
        self.isLoggedIn = isLoggedIn
    }

    public var body: some View {

        if isLoggedIn {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.hasNoEdits {
                        noEditsView
                        if viewModel.shouldShowStartEditing {
                            startEditingButton
                        } else if viewModel.shouldShowAddAnImage {
                            addAnImageButton
                        }
                    } else if viewModel.shouldShowAddAnImage {
                        Text(viewModel.suggestedEdits)
                        addAnImageButton // TODO: add editing activity item above
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
                    let dataController = try WMFActivityDataController()
                    dataController.savedSlideDataDelegate = viewModel.savedSlideDataDelegate
                    dataController.legacyPageViewsDataDelegate = viewModel.legacyPageViewsDataDelegate
                    let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
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
            WMFActivityTabLoggedOutView()
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

    private var addAnImageButton: some View {
        HStack {
            VStack {
                Text(viewModel.addAnImageTitle)
                Text(viewModel.addAnImageSubtitle)
                Button(action: {
                    print("Start editing")
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                        Text(viewModel.addAnImageTitle)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color(theme.link))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(theme.midBackground))
        .overlay(
            Rectangle()
                .stroke(Color(theme.text), lineWidth: 1)
        )
    }
}
