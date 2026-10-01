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

    private var isOverCharacterLimit: Bool {
        guard let characterLimit = viewModel.otherTextCharacterLimit else { return false }
        return otherOptionText.count > characterLimit
    }

    private var canSubmit: Bool {
        userHasSelectedReasons && !isOverCharacterLimit
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
                } header: {
                    VStack(alignment: .leading, spacing: 8) {
                        if let heading = viewModel.localizedStrings.heading {
                            Text(heading)
                                .font(Font(WMFFont.for(.semiboldHeadline)))
                                .foregroundColor(Color(theme.text))
                        }
                        Text(viewModel.localizedStrings.subtitle)
                            .font(Font(WMFFont.for(.callout)))
                            .foregroundColor(Color(theme.secondaryText))
                        if let instructions = viewModel.localizedStrings.instructions {
                            Text(instructions)
                                .font(Font(WMFFont.for(.italicCallout)))
                                .foregroundColor(Color(theme.secondaryText))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textCase(nil)
                    .listRowInsets(EdgeInsets())
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
                .listSectionSeparator(.hidden)

                Section {
                    if viewModel.shouldShowMultilineText {
                        multilineTextInput()
                        .listRowBackground(Color(theme.paperBackground))
                    } else {
                        HStack {
                            TextField(viewModel.localizedStrings.otherPlaceholder, text: $otherOptionText)
                                .focused($otherOptionTextFieldSelected)
                                .foregroundStyle(Color(theme.text))
                            Spacer()
                            WMFCheckmarkView(isSelected: !otherOptionText.isEmpty, configuration: WMFCheckmarkView.Configuration(style: .default))
                        }
                        .listRowBackground(Color(theme.paperBackground))
                    }

                } footer: {
                    if let characterLimit = viewModel.otherTextCharacterLimit {
                        HStack {
                            if isOverCharacterLimit, let characterLimitErrorText = viewModel.localizedStrings.characterLimitErrorText {
                                Text(characterLimitErrorText)
                                    .foregroundColor(Color(theme.destructive))
                            }
                            Spacer()
                            Text("\(otherOptionText.count)/\(characterLimit)")
                                .foregroundColor(Color(isOverCharacterLimit ? theme.destructive : theme.secondaryText))
                        }
                        .font(Font(WMFFont.for(.caption1)))
                    }
                }
                .listCustomSectionSpacing(16)
                .listRowSeparator(.hidden)
            }
            .listBackgroundColor(Color(theme.baseBackground))
            .listStyle(.insetGrouped)
            .background(Color(theme.baseBackground))
            .navigationTitle(viewModel.localizedStrings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close) {
                            cancelAction?()
                        }
                    } else {
                        Button {
                            cancelAction?()
                        } label: {
                            Image(uiImage: WMFSFSymbolIcon.for(symbol: .close) ?? UIImage())
                        }
                        .foregroundStyle(Color(theme.link))
                        .accessibilityLabel(viewModel.localizedStrings.cancel)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.localizedStrings.submit) {
                        if !otherOptionText.isEmpty {
                            selectedOptions.insert("other")
                        }
                        submitAction?(Array(selectedOptions), otherOptionText)
                    }
                    .disabled(!canSubmit)
                    .foregroundStyle(Color(canSubmit ? theme.link : theme.secondaryText))
                }
            }
            }
            .navigationViewStyle(.stack)
            .environment(\.colorScheme, theme.preferredColorScheme)
    }
    
    private func multilineTextInput() -> some View {
        VStack {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $otherOptionText)
                    .frame(height: 80)
                    .focused($otherOptionTextFieldSelected)
                    .foregroundColor(Color(theme.text))
                    .background(Color(theme.paperBackground))
                    .cornerRadius(8)
                    .padding([.top, .horizontal], 4)

                if otherOptionText.isEmpty && !otherOptionTextFieldSelected {
                    Text(viewModel.localizedStrings.otherPlaceholder)
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                        .padding(.top, 10)
                        .padding(.leading, 8)
                }
                HStack {
                    Spacer()
                    WMFCheckmarkView(
                        isSelected: !otherOptionText.isEmpty,
                        configuration: WMFCheckmarkView.Configuration(style: .default)
                    )
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            otherOptionTextFieldSelected = true
        }
    }
}

#Preview {
WMFSurveyView(viewModel: WMFSurveyViewModel(localizedStrings: .init(title: "Reason", cancel: "Cancel", submit: "Submit", subtitle: "Improve", instructions: "Select", otherPlaceholder: "Other"), options: [WMFSurveyViewModel.OptionViewModel(text: "Image is not relevant", apiIdentifer: "notrelevant")], selectionType: .multi))
}
