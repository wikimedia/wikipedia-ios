import Foundation

public final class WKFormViewModel: ObservableObject {
    @Published var sections: [WKFormSectionViewModel]

    public init(sections: [WKFormSectionViewModel]) {
        self.sections = sections
    }
}
