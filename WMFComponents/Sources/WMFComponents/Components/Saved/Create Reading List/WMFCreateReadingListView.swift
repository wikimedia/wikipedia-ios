import SwiftUI
import WMFNativeLocalizations

public struct WMFCreateReadingListView: View {

    private enum Field: Hashable {
        case name
        case description
    }

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFCreateReadingListViewModel
    @FocusState private var focusedField: Field?

    private let namePlaceholder = WMFLocalizedString("reading-list-new-list-name-placeholder", value: "reading list title", comment: "Placeholder text appearing in text field for entering new list name")
    private let descriptionPlaceholder = WMFLocalizedString("reading-list-new-list-description-placeholder", value: "optional short description", comment: "Placeholder text appearing in text field for entering new list description")

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFCreateReadingListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color(theme.paperBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: WMFSpacing.small) {
                    fieldsContainer
                    if let nameErrorMessage = viewModel.nameErrorMessage {
                        Text(nameErrorMessage)
                            .font(Font(WMFFont.for(.caption1)))
                            .foregroundStyle(Color(theme.destructive))
                            .padding(.horizontal, WMFSpacing.large)
                            .accessibilityIdentifier(AccessibilityIdentifiers.CreateReadingList.nameErrorLabel)
                    }
                }
                .padding(.horizontal, WMFSpacing.large)
                .padding(.top, WMFSpacing.xLarge)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(AccessibilityIdentifiers.CreateReadingList.view)
            }
            .scrollDismissesKeyboard(.interactively)

            if viewModel.isImporting {
                Color(theme.paperBackground)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(Color(theme.secondaryText))
            }
        }
        .onAppear {
            if viewModel.focusesNameOnAppear {
                focusedField = .name
            }
        }
    }

    // MARK: - Subviews

    private var fieldsContainer: some View {
        VStack(spacing: 0) {
            nameTextField
            Divider()
                .background(Color(theme.border))
            descriptionTextField
        }
        .padding(.horizontal, WMFSpacing.large)
        .background(
            RoundedRectangle(cornerRadius: WMFCornerRadius.large)
                .fill(Color(theme.baseBackground))
        )
    }

    private var nameTextField: some View {
        textField(placeholder: namePlaceholder, text: $viewModel.name, field: .name)
            .foregroundStyle(Color(viewModel.nameErrorMessage == nil ? theme.text : theme.destructive))
            .submitLabel(.next)
            .onSubmit {
                focusedField = .description
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.CreateReadingList.nameTextField)
    }

    private var descriptionTextField: some View {
        textField(placeholder: descriptionPlaceholder, text: $viewModel.description, field: .description)
            .foregroundStyle(Color(theme.text))
            .submitLabel(.done)
            .onSubmit {
                focusedField = nil
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.CreateReadingList.descriptionTextField)
    }

    private func textField(placeholder: String, text: Binding<String>, field: Field) -> some View {
        TextField(
            "",
            text: text,
            prompt: Text(placeholder).foregroundColor(Color(theme.secondaryText))
        )
        .font(Font(WMFFont.for(.body)))
        .tint(Color(theme.link))
        .focused($focusedField, equals: field)
        .disabled(!viewModel.isInputEnabled)
        .padding(.vertical, WMFSpacing.large)
    }
}
