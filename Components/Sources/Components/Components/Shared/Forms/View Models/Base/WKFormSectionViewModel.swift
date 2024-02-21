import Foundation

public class WKFormSectionViewModel: Identifiable {
    public let id = UUID()
    let header: String?
    let footer: String?
    
    public init(header: String?, footer: String?) {
        self.header = header
        self.footer = footer
    }
}
