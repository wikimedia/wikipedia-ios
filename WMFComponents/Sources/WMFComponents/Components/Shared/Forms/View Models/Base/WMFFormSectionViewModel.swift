import Foundation

public class WMFFormSectionViewModel: Identifiable {
    public let id = UUID()
    let header: String?
    let footer: String?
    
    public init(header: String?, footer: String?) {
        self.header = header
        self.footer = footer
    }
}
