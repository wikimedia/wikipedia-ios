import Foundation

public final class WMFSurveyViewModel {

	public struct LocalizedStrings {
		let title: String
		let cancel: String
		let submit: String
		let subtitle: String
		let instructions: String?

		let otherPlaceholder: String

        public init(title: String, cancel: String, submit: String, subtitle: String, instructions: String?, otherPlaceholder: String) {
			self.title = title
			self.cancel = cancel
			self.submit = submit
			self.subtitle = subtitle
			self.instructions = instructions
			self.otherPlaceholder = otherPlaceholder
		}
	}
    
    public struct OptionViewModel: Hashable, Identifiable {
        public let id = UUID()
        public let text: String
        public let apiIdentifer: String
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(apiIdentifer)
        }
        
        public static func == (lhs: WMFSurveyViewModel.OptionViewModel, rhs: WMFSurveyViewModel.OptionViewModel) -> Bool {
            return lhs.apiIdentifer == rhs.apiIdentifer
        }
        
        public init(text: String, apiIdentifer: String) {
            self.text = text
            self.apiIdentifer = apiIdentifer
        }
    }
    
    public enum SelectionType {
        case multi
        case single
    }

	let localizedStrings: LocalizedStrings
    let options: [OptionViewModel]
    let selectionType: SelectionType

    public init(localizedStrings: LocalizedStrings, options: [OptionViewModel], selectionType: SelectionType) {
		self.localizedStrings = localizedStrings
        self.options = options
        self.selectionType = selectionType
	}

}
