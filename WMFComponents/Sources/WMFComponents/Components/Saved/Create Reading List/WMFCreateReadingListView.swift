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

    private let namePlaceholder = WMFLocalizedString("reading-list-new-list-name-placeholder", value: "Reading list title", comment: "Placeholder text appearing in text field for entering new list name")
    private let descriptionPlaceholder = WMFLocalizedString("reading-list-new-list-description-placeholder", value: "Optional short description", comment: "Placeholder text appearing in text field for entering new list description")

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
                VStack(spacing: 0) {
                    form
                    if !viewModel.articleRows.isEmpty {
                        articleRows
                    }
                }
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

    private var form: some View {
        VStack(alignment: .leading, spacing: WMFSpacing.small) {
            if let subtitle = viewModel.subtitle {
                Text(subtitle)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundStyle(Color(theme.secondaryText))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, WMFSpacing.small)
            }
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
        .padding(.bottom, viewModel.articleRows.isEmpty ? 0 : WMFSpacing.large)
    }

    private var articleRows: some View {
        LazyVStack(spacing: 0) {
            divider
            ForEach(viewModel.articleRows) { rowViewModel in
                WMFPageRowSaved(
                    viewModel: rowViewModel,
                    onTap: { _ in
                        viewModel.toggleSelection(of: rowViewModel.id)
                    },
                    onDelete: { _ in },
                    onShare: { _, _ in },
                    onOpenInNewTab: {},
                    onOpenInBackgroundTab: {},
                    showsContextMenu: false
                )
                .background(Color(viewModel.allowsArticleSelection && viewModel.isSelected(rowViewModel.id) ? theme.batchSelectionBackground : theme.paperBackground), ignoresSafeAreaEdges: [])
                .allowsHitTesting(viewModel.allowsArticleSelection)
                .accessibilityRemoveTraits(viewModel.allowsArticleSelection ? [] : .isButton)
                .accessibilityAddTraits(viewModel.allowsArticleSelection && viewModel.isSelected(rowViewModel.id) ? .isSelected : [])
                .accessibilityIdentifier(AccessibilityIdentifiers.CreateReadingList.articleRow(rowViewModel.title))
                .disabled(!viewModel.isInputEnabled || viewModel.isCreating)

                divider
            }
        }
    }

    private var divider: some View {
        Divider()
            .background(Color(theme.border), ignoresSafeAreaEdges: [])
    }

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
