import Foundation

extension String {

	public func wkRemovingHTML() -> String {
		return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
	}

}
