import Foundation
import WMFData
import SwiftUI

public final class WMFWatchlistViewModel: ObservableObject {

	// MARK: - Nested Types

	public struct LocalizedStrings {
		public var title: String
		public var filter: String
		public var userButtonUserPage: String
		public var userButtonTalkPage: String
		public var userButtonContributions: String
		public var userButtonThank: String
        public var emptyEditSummary: String
        public var userAccessibility: String
        public var summaryAccessibility: String
        public var userAccessibilityButtonDiff: String
        public var localizedProjectNames: [WMFProject: String]

		public var byteChange: ((Int) -> String) // for injecting localized plurals via client app
		public let htmlStripped: ((String) -> String) // use client app logic to strip HTML tags

        public init(title: String, filter: String, userButtonUserPage: String, userButtonTalkPage: String, userButtonContributions: String, userButtonThank: String, emptyEditSummary: String, userAccessibility: String, summaryAccessibility: String, userAccessibilityButtonDiff: String, localizedProjectNames: [WMFProject: String], byteChange: @escaping ((Int) -> String), htmlStripped: @escaping ((String) -> String)) {

			self.title = title
			self.filter = filter
			self.userButtonUserPage = userButtonUserPage
			self.userButtonTalkPage = userButtonTalkPage
			self.userButtonContributions = userButtonContributions
			self.userButtonThank = userButtonThank
            self.emptyEditSummary = emptyEditSummary
            self.userAccessibility = userAccessibility
            self.summaryAccessibility = summaryAccessibility
            self.userAccessibilityButtonDiff = userAccessibilityButtonDiff
            self.localizedProjectNames = localizedProjectNames
			self.byteChange = byteChange
			self.htmlStripped = htmlStripped
		}
	}

	public struct ItemViewModel: Identifiable {
		public static let wmfProjectMetadataKey = String(describing: WMFProject.self)
		public static let revisionIDMetadataKey = "RevisionID"
        public static let oldRevisionIDMetadataKey = "OldRevisionID"
        public static let articleMetadataKey = "ArticleTitle"

		public let id = UUID()

		let title: String
		let commentHTML: String
		let commentWikitext: String
		let timestamp: Date
		let username: String
		let isAnonymous: Bool
		let isBot: Bool
		let revisionID: UInt
		let oldRevisionID: UInt
		let byteChange: Int
		let project: WMFProject
		private let htmlStripped: ((String) -> String)

		public init(title: String, commentHTML: String, commentWikitext: String, timestamp: Date, username: String, isAnonymous: Bool, isBot: Bool, revisionID: UInt, oldRevisionID: UInt, byteChange: Int, project: WMFProject, htmlStripped: @escaping ((String) -> String)) {
			self.title = title
			self.commentHTML = commentHTML
			self.commentWikitext = commentWikitext
			self.timestamp = timestamp
			self.username = username
			self.isAnonymous = isAnonymous
			self.isBot = isBot
			self.revisionID = revisionID
			self.oldRevisionID = oldRevisionID
			self.byteChange = byteChange
			self.project = project
			self.htmlStripped = htmlStripped
		}

		var timestampString: String {
			return DateFormatter.wmfShortTimeFormatter.string(from: timestamp)
		}

        var timestampStringAccessibility: String {
            return DateFormatter.wmfShortTimeFormatter.string(from: timestamp)
        }

		func bytesString(localizedStrings: LocalizedStrings) -> String {
			return localizedStrings.byteChange(byteChange)
		}

		var bytesTextColorKeyPath: KeyPath<WMFTheme, UIColor> {
			if byteChange == 0 {
				return \.secondaryText
			} else if byteChange > 0 {
				return \.accent
			} else {
				return \.destructive
			}
		}

		var comment: String {
			return htmlStripped(commentHTML)
		}

	}

	struct SectionViewModel: Identifiable {
		public let id = UUID()

		let date: Date
		let items: [ItemViewModel]

		var title: String {
			return DateFormatter.wmfFullDateFormatter.string(from: date)
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

	private let dataController = WMFWatchlistDataController()
	private var items: [ItemViewModel] = []

	@Published var sections: [SectionViewModel] = []
    @Published public var activeFilterCount: Int = 0
	@Published var hasPerformedInitialFetch = false

	var menuButtonItems: [WMFSmallMenuButton.MenuItem]
	var menuButtonItemsWithoutThank: [WMFSmallMenuButton.MenuItem]

	// MARK: - Lifecycle

    public init(localizedStrings: LocalizedStrings, presentationConfiguration: PresentationConfiguration) {
		self.localizedStrings = localizedStrings
        self.presentationConfiguration = presentationConfiguration
		self.menuButtonItems = []
        self.menuButtonItemsWithoutThank = []
        setupMenuItems()
	}

    private func setupMenuItems() {
        var menuItems: [WMFSmallMenuButton.MenuItem] = [
            WMFSmallMenuButton.MenuItem(title: localizedStrings.userButtonUserPage, image: WMFSFSymbolIcon.for(symbol: .person)),
            WMFSmallMenuButton.MenuItem(title: localizedStrings.userButtonTalkPage, image: WMFSFSymbolIcon.for(symbol: .conversation)),
            WMFSmallMenuButton.MenuItem(title: localizedStrings.userButtonContributions, image: WMFIcon.userContributions),
            WMFSmallMenuButton.MenuItem(title: localizedStrings.userButtonThank, image: WMFIcon.thank)
        ]

        if UIAccessibility.isVoiceOverRunning {
			let diffForAccessibility = WMFSmallMenuButton.MenuItem(title: localizedStrings.userAccessibilityButtonDiff, image: nil)
            menuItems.insert(diffForAccessibility, at: 0)
        }
        menuButtonItems = menuItems
        menuButtonItemsWithoutThank = menuButtonItems.dropLast()
    }

	 public func fetchWatchlist(_ completion: (() -> Void)? = nil) {
        dataController.fetchWatchlist { result in
			switch result {
			case .success(let watchlist):
				self.items = watchlist.items.map { item in
					let viewModel = ItemViewModel(title: item.title, commentHTML: item.commentHtml, commentWikitext: item.commentWikitext, timestamp: item.timestamp, username: item.username, isAnonymous: item.isAnon, isBot: item.isBot, revisionID: item.revisionID, oldRevisionID: item.oldRevisionID, byteChange: Int(item.byteLength) - Int(item.oldByteLength), project: item.project, htmlStripped: self.localizedStrings.htmlStripped)
					return viewModel
				}
				self.sections = self.sortWatchlistItems()
                self.activeFilterCount = watchlist.activeFilterCount
			case .failure:
				break
			}
			self.hasPerformedInitialFetch = true
            completion?()
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
