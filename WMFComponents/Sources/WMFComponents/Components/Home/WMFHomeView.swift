import SwiftUI

public struct WMFHomeView: View {

    @ObservedObject var viewModel: WMFHomeViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFHomeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("", selection: $viewModel.selectedTab) {
                    Text(viewModel.forYouTabTitle).tag(WMFHomeViewModel.Tab.forYou)
                    Text(viewModel.communityTabTitle).tag(WMFHomeViewModel.Tab.community)
                }
                .pickerStyle(.segmented)

                Menu {
                    ForEach(viewModel.languages) { language in
                        Button {
                            viewModel.didSelectLanguage?(language.code)
                        } label: {
                            if language.code == viewModel.selectedLanguageCode {
                                Label(language.localizedName, systemImage: "checkmark")
                            } else {
                                Text(language.localizedName)
                            }
                        }
                    }

                    Divider()

                    Button {
                        viewModel.didTapEditLanguages?()
                    } label: {
                        Label(viewModel.editLanguagesTitle, systemImage: "globe")
                    }
                } label: {
                    Text(viewModel.languageButtonTitle)
                        .font(Font(WMFFont.for(.semiboldHeadline)))
                        .foregroundStyle(Color(uiColor: theme.link))
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Home.languagePickerButton)
            }
            .padding()

            Spacer()

            // Temporary placeholder content until the Home feed is built out.
            Text(currentTabTitle)
                .font(Font(WMFFont.for(.headline)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: theme.paperBackground))
        .environment(\.colorScheme, theme.preferredColorScheme)
    }

    private var currentTabTitle: String {
        switch viewModel.selectedTab {
        case .forYou:
            return viewModel.forYouTabTitle
        case .community:
            return viewModel.communityTabTitle
        }
    }
}
