import Foundation
import WKData
import SwiftUI

public final class WKWatchlistViewModel: ObservableObject {

	// MARK: - Nested Types

	public struct LocalizedStrings {
		public var title: String
		public var filter: String
		public var byteChange: ((Int) -> String) // for injecting localized plurals via client app

		public init(title: String, filter: String, byteChange: @escaping ((Int) -> String)) {
			self.title = title
			self.filter = filter
			self.byteChange = byteChange
		}
	}

	struct ItemViewModel: Identifiable {
		public let id = UUID()

		let title: String
		let commentHTML: String
		let commentWikitext: String
		let timestamp: Date
		let username: String
		let revisionID: UInt
		let byteChange: Int
		let project: WKProject

		public init(title: String, commentHTML: String, commentWikitext: String, timestamp: Date, username: String, revisionID: UInt, byteChange: Int, project: WKProject) {
			self.title = title
			self.commentHTML = commentHTML
			self.commentWikitext = commentWikitext
			self.timestamp = timestamp
			self.username = username
			self.revisionID = revisionID
			self.byteChange = byteChange
			self.project = project
		}

		var timestampString: String {
			return DateFormatter.wkShortTimeFormatter.string(from: timestamp)
		}

		func bytesString(localizedStrings: LocalizedStrings) -> String {
			return localizedStrings.byteChange(byteChange)
		}

		var bytesTextColorKeyPath: KeyPath<WKTheme, UIColor> {
			if byteChange == 0 {
				return \.secondaryText
			} else if byteChange > 0 {
				return \.accent
			} else {
				return \.destructive
			}
		}

		var comment: String {
			return commentHTML.wkRemovingHTML()
		}

	}

	struct SectionViewModel: Identifiable {
		public let id = UUID()

		let date: Date
		let items: [ItemViewModel]

		var title: String {
			return DateFormatter.wkFullDateFormatter.string(from: date)
		}
	}
    
    public struct PresentationConfiguration {
        let showNavBarUponAppearance: Bool
        let hideNavBarUponDisappearance: Bool
        
        public init(showNavBarUponAppearance: Bool = false, hideNavBarUponDisappearance: Bool = false) {
            self.showNavBarUponAppearance = showNavBarUponAppearance
            self.hideNavBarUponDisappearance = hideNavBarUponDisappearance
        }
    }

	// MARK: - Properties

	var localizedStrings: LocalizedStrings
    let presentationConfiguration: PresentationConfiguration

	private let dataController = WKWatchlistDataController()
	private var items: [ItemViewModel] = []

	@Published var sections: [SectionViewModel] = []
    @Published var activeFilterCount: Int = 0

	// MARK: - Lifecycle

    public init(localizedStrings: LocalizedStrings, presentationConfiguration: PresentationConfiguration) {
		self.localizedStrings = localizedStrings
        self.presentationConfiguration = presentationConfiguration
		fetchWatchlist()
	}

	public func fetchWatchlist() {
        dataController.fetchWatchlist { result in
			switch result {
			case .success(let watchlist):
				self.items = watchlist.items.map { item in
					let viewModel = ItemViewModel(title: item.title, commentHTML: item.commentHtml, commentWikitext: item.commentWikitext, timestamp: item.timestamp, username: item.username, revisionID: item.revisionID, byteChange: Int(item.byteLength) - Int(item.oldByteLength), project: item.project)
					return viewModel
				}
				self.sections = self.sortWatchlistItems()
                self.activeFilterCount = watchlist.activeFilterCount
			case .failure(_):
				break
			}
		}
	}

	/// Sort Watchlist items into "day" buckets with all revisions per day, descending by date
	private func sortWatchlistItems() -> [SectionViewModel] {
		let calendar = Calendar.current
		var sectionDictionary: [Date: [ItemViewModel]] = [:]
		var sectionViewModels: [SectionViewModel] = []

		for item in items {
			let dayOfItem = calendar.startOfDay(for: item.timestamp)
			if var sectionElements = sectionDictionary[dayOfItem] {
				sectionElements.append(item)
				sectionDictionary[dayOfItem] = sectionElements
			} else {
				sectionDictionary[dayOfItem] = [item]
			}
		}

		for date in sectionDictionary.keys.sorted(by: { $0 > $1 }) {
			let sortedItems = sectionDictionary[date]?.sorted(by: { $0.timestamp > $1.timestamp }) ?? []
			let section = SectionViewModel(date: date, items: sortedItems)
			sectionViewModels.append(section)
		}

		return sectionViewModels
	}
	
}
