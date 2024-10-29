import SwiftUI

public struct WMFSurveyView: View {

    public typealias OptionAPIIdentifier = String
    public typealias OtherText = String

    // MARK: - Properties

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    private var userHasSelectedReasons: Bool {
        return !selectedOptions.isEmpty || !otherOptionText.isEmpty
    }

    @FocusState var otherOptionTextFieldSelected: Bool

    @State var otherOptionText = ""
    @State var selectedOptions: Set<OptionAPIIdentifier> = []

    let viewModel: WMFSurveyViewModel

    var cancelAction: (() -> Void)?
    var submitAction: (([OptionAPIIdentifier], OtherText) -> Void)?

    public init(appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current, viewModel: WMFSurveyViewModel, cancelAction: (() -> Void)? = nil, submitAction: (([WMFSurveyView.OptionAPIIdentifier], WMFSurveyView.OtherText) -> Void)? = nil) {
        self.appEnvironment = appEnvironment
        self.viewModel = viewModel
        self.cancelAction = cancelAction
        self.submitAction = submitAction
    }

    // MARK: - View

    public var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading) {
                        Text(viewModel.localizedStrings.subtitle)
                            .font(Font(WMFFont.for(.callout)))
                        if let instructions = viewModel.localizedStrings.instructions {
                            Text(instructions)
                                .font(Font(WMFFont.for(.italicCallout)))
                        }
                    }
                }
                .foregroundColor(Color(theme.secondaryText))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listCustomSectionSpacing(0)

                Section {
                    ForEach(viewModel.options) { optionViewModel in
                        HStack {
                            Text(optionViewModel.text)
                                .foregroundStyle(Color(theme.text))
                            Spacer()
                            WMFCheckmarkView(isSelected: selectedOptions.contains(optionViewModel.apiIdentifer), configuration: WMFCheckmarkView.Configuration(style: .default))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            otherOptionTextFieldSelected = false

                            switch viewModel.selectionType {
                            case .multi:
                                if selectedOptions.contains(optionViewModel.apiIdentifer) {
                                    selectedOptions.remove(optionViewModel.apiIdentifer)
                                } else {
                                    selectedOptions.insert(optionViewModel.apiIdentifer)
                                }
                            case .single:
                                for option in selectedOptions {
                                    selectedOptions.remove(option)
                                }
                                selectedOptions.insert(optionViewModel.apiIdentifer)
                            }

                        }
                    }
                    .listRowBackground(Color(theme.paperBackground))
                    .listRowSeparatorTint(Color(theme.newBorder))
                }
                .listSectionSeparator(.hidden)

                Section {
                    HStack {
                        TextField(viewModel.localizedStrings.otherPlaceholder, text: $otherOptionText)
                            .focused($otherOptionTextFieldSelected)
                            .foregroundStyle(Color(theme.text))
                        Spacer()
                        WMFCheckmarkView(isSelected: !otherOptionText.isEmpty, configuration: WMFCheckmarkView.Configuration(style: .default))
                    }
                    .listRowBackground(Color(theme.paperBackground))
                }
                .listCustomSectionSpacing(16)
                .listRowSeparator(.hidden)
            }
            .listBackgroundColor(Color(theme.midBackground))
            .listStyle(.plain)
            .navigationTitle(viewModel.localizedStrings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(viewModel.localizedStrings.cancel) {
                        cancelAction?()
                    }
                    .foregroundStyle(Color(theme.link))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.localizedStrings.submit) {
                        if !otherOptionText.isEmpty {
                            selectedOptions.insert("other")
                        }
                        submitAction?(Array(selectedOptions), otherOptionText)
                    }
                    .disabled(!userHasSelectedReasons)
                    .foregroundStyle(Color(userHasSelectedReasons ? theme.link : theme.secondaryText))
                }
            }
            }
            .navigationViewStyle(.stack)
            .environment(\.colorScheme, theme.preferredColorScheme)
    }

}

#Preview {
WMFSurveyView(viewModel: WMFSurveyViewModel(localizedStrings: .init(title: "Reason", cancel: "Cancel", submit: "Submit", subtitle: "Improve", instructions: "Select", otherPlaceholder: "Other"), options: [WMFSurveyViewModel.OptionViewModel(text: "Image is not relevant", apiIdentifer: "notrelevant")], selectionType: .multi))
}
