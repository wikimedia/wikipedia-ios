import Foundation
import WMFNativeLocalizations

@MainActor
public final class WMFCreateReadingListViewModel: ObservableObject {

    public enum Mode: Equatable {
        case create
        case importSharedList
    }

    @Published public var name: String = "" {
        didSet {
            guard name != oldValue else { return }
            nameErrorMessage = nil
        }
    }
    @Published public var description: String = ""
    @Published public private(set) var nameErrorMessage: String?
    @Published public private(set) var isImporting: Bool
    @Published public private(set) var isInputEnabled = true
    /// The host sets it while it saves the list, so the user cannot tap Create twice.
    @Published public var isCreating = false

    public let mode: Mode
    public var didTapCreate: ((_ name: String, _ description: String) -> Void)?
    public var didTapClose: (() -> Void)?
    /// Called once the form leaves the screen, by any path.
    public var didDismiss: (() -> Void)?

    let title: String

    private let importedListDefaultName = WMFLocalizedString("import-shared-reading-list-default-title", value: "My Reading List", comment: "Default title of a reading list imported through a shared link.")

    public init(mode: Mode) {
        self.mode = mode
        isImporting = mode == .importSharedList
        switch mode {
        case .create:
            title = CommonStrings.createNewListTitle
        case .importSharedList:
            title = WMFLocalizedString("import-shared-reading-list-title", value: "Import shared reading list", comment: "Title of screen that imports a shared reading list.")
        }
    }

    // MARK: - State

    public var isCreateButtonEnabled: Bool {
        !trimmedName.isEmpty && nameErrorMessage == nil && !isImporting && isInputEnabled && !isCreating
    }

    var focusesNameOnAppear: Bool {
        mode == .create
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Actions

    public func tapCreate() {
        guard isCreateButtonEnabled else { return }
        didTapCreate?(trimmedName, description.trimmingCharacters(in: .whitespaces))
    }

    public func tapClose() {
        didTapClose?()
    }

    // MARK: - Host callbacks

    public func showNameError(_ message: String) {
        nameErrorMessage = message
    }

    public func importDidSucceed() {
        isImporting = false
        name = importedListDefaultName
    }

    public func importDidFail() {
        isImporting = false
        isInputEnabled = false
    }
}
