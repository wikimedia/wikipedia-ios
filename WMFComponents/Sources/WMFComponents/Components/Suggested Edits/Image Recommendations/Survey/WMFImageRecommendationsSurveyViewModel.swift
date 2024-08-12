import Foundation

public final class WMFImageRecommendationsSurveyViewModel {

	public struct LocalizedStrings {
		let reason: String
		let cancel: String
		let submit: String

		let improveSuggestions: String
		let selectOptions: String

		let imageNotRelevant: String
		let notEnoughInformation: String
		let imageIsOffensive: String
		let imageIsLowQuality: String
		let dontKnowSubject: String
		let other: String

		public init(reason: String, cancel: String, submit: String, improveSuggestions: String, selectOptions: String, imageNotRelevant: String, notEnoughInformation: String, imageIsOffensive: String, imageIsLowQuality: String, dontKnowSubject: String, other: String) {
			self.reason = reason
			self.cancel = cancel
			self.submit = submit
			self.improveSuggestions = improveSuggestions
			self.selectOptions = selectOptions
			self.imageNotRelevant = imageNotRelevant
			self.notEnoughInformation = notEnoughInformation
			self.imageIsOffensive = imageIsOffensive
			self.imageIsLowQuality = imageIsLowQuality
			self.dontKnowSubject = dontKnowSubject
			self.other = other
		}
	}

	enum Reason: Hashable, Identifiable {
		case imageNotRelevant
		case notEnoughInformation
		case imageIsOffensive
		case imageIsLowQuality
		case dontKnowSubject
		case other(reason: String)

		var id: Self {
			return self
		}

		func localizedPlaceholder(from localizedStrings: LocalizedStrings) -> String {
			switch self {
			case .imageNotRelevant:
				return localizedStrings.imageNotRelevant
			case .notEnoughInformation:
				return localizedStrings.notEnoughInformation
			case .imageIsOffensive:
				return localizedStrings.imageIsOffensive
			case .imageIsLowQuality:
				return localizedStrings.imageIsLowQuality
			case .dontKnowSubject:
				return localizedStrings.dontKnowSubject
			case .other:
				return localizedStrings.other
			}
		}
        
        var otherText: String? {
            switch self {
            case .other(let reason):
                return reason
            default:
                return nil
            }
        }

		var apiIdentifier: String {
			switch self {
			case .imageNotRelevant:
				return "notrelevant"
			case .notEnoughInformation:
				return "noinfo"
			case .imageIsOffensive:
				return "offensive"
			case .imageIsLowQuality:
				return "lowquality"
			case .dontKnowSubject:
				return "unfamiliar"
			case .other:
				return "other"
			}
		}
	}

	let localizedStrings: LocalizedStrings

	let presetReasons: [Reason] = [.imageNotRelevant, .notEnoughInformation, .imageIsOffensive, .imageIsLowQuality, .dontKnowSubject]

	init(localizedStrings: LocalizedStrings) {
		self.localizedStrings = localizedStrings
	}

}
