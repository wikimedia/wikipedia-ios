import Foundation

public final class WMFFormViewModel: ObservableObject {
    @Published var sections: [WMFFormSectionViewModel]

    public init(sections: [WMFFormSectionViewModel]) {
        self.sections = sections
    }
}
