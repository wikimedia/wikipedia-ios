import Foundation

public final class WMFFormViewModel: ObservableObject {
    @Published var sections: [WKFormSectionViewModel]

    public init(sections: [WKFormSectionViewModel]) {
        self.sections = sections
    }
}
