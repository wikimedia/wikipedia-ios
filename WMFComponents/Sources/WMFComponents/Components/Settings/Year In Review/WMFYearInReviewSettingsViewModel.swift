import Foundation

@MainActor
final class WMFYearInReviewSettingsViewModel: ObservableObject {

    struct LocalizedStrings {
        let title: String
        let description: String
        let toggleTitle: String

        static let `default` = LocalizedStrings(
            title: "Resumo do ano",
            description: "Desativar o resumo do ano apagará todas as informações personalizadas armazenadas e ocultará o Resumo do ano.",
            toggleTitle: "Resumo do ano"
        )
    }

    @Published var isEnabled: Bool = false
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?

    private let strings: LocalizedStrings
    private let dataController: WMFYearInReviewDataController

    var title: String { strings.title }
    var descriptionText: String { strings.description }
    var toggleTitle: String { strings.toggleTitle }

    init(
        dataController: WMFYearInReviewDataController,
        strings: LocalizedStrings = .default
    ) {
        self.dataController = dataController
        self.strings = strings

        Task { await load() }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // If this is sync, it’s still fine to read on MainActor.
        isEnabled = dataController.yearInReviewSettingsIsEnabled
    }

    func setEnabled(_ newValue: Bool) async {
        errorMessage = nil

        // Optimistic UI update
        let oldValue = isEnabled
        isEnabled = newValue

        do {
            // ✅ Prefer an async setter if you have one (recommended).
            // try await dataController.setYearInReviewSettingsEnabled(newValue)

            // ✅ If you only have a sync setter, call it directly.
            // dataController.yearInReviewSettingsIsEnabled = newValue

            // If you don't have either yet, add one (see section 4).
        } catch {
            isEnabled = oldValue
            errorMessage = error.localizedDescription
        }
    }
}
