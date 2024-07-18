import Foundation

extension String {
    public var removingHTML: String {
        return (try? HtmlUtils.stringFromHTML(self)) ?? self
    }
}
