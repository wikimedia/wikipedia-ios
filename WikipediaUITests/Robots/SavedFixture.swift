import Foundation

/// The seeded data and the localized labels the Saved tab tests rely on, per fixture language.
///
/// Four articles and three reading lists are seeded. Their names are chosen so that
/// "by title" and "recently added" give different orders, and so that a localized,
/// case- and accent-insensitive title sort differs from a binary string sort.
/// The first list holds only Latin titles, so its binary and localized orders differ in every
/// language, including Hebrew, where the openable title would sort last either way.
struct SavedFixture {
    struct Labels {
        let allArticlesScope: String
        let readingListsScope: String
        let sort: String
        let sortByTitle: String
        let sortByRecentlyAdded: String
        let edit: String
        let cancel: String
        let unsave: String
        let delete: String
        let removeFromSaved: String
        let createNewList: String
    }

    /// The article from the ArticleControls fixtures, so it can be opened in fixture-backed runs.
    let openableArticleTitle: String
    let labels: Labels

    // Articles that only exist as saved rows. They are never opened.
    static let lowercaseArticleTitle = "apple"
    static let accentedArticleTitle = "Émile Zola"
    static let latestArticleTitle = "Zebra"
    /// Shown in the long-press preview of the latest article.
    static let latestArticleSnippet = "Zebras are African equines with striped coats."

    // Reading lists. `firstListName` holds the three Latin titles; `lowercaseListName` holds the openable article.
    static let firstListName = "Zoology"
    static let lowercaseListName = "animals"
    static let accentedListName = "Égypte"
    static let newListName = "Birds"

    var seed: UITestReadingListsSeed {
        UITestReadingListsSeed(
            readingLists: [
                .init(name: Self.firstListName, description: "Animals and their study", createdMinutesAgo: 60),
                .init(name: Self.lowercaseListName, description: nil, createdMinutesAgo: 30),
                .init(name: Self.accentedListName, description: "Empty on purpose", createdMinutesAgo: 10)
            ],
            articles: [
                .init(title: openableArticleTitle, description: "domesticated animal", snippet: nil, savedMinutesAgo: 10, readingListNames: [Self.lowercaseListName]),
                .init(title: Self.lowercaseArticleTitle, description: "fruit", snippet: nil, savedMinutesAgo: 3, readingListNames: [Self.firstListName]),
                .init(title: Self.accentedArticleTitle, description: "French writer", snippet: nil, savedMinutesAgo: 2, readingListNames: [Self.firstListName]),
                .init(title: Self.latestArticleTitle, description: "striped mammal", snippet: Self.latestArticleSnippet, savedMinutesAgo: 1, readingListNames: [Self.firstListName])
            ]
        )
    }

    /// Only the lists, with nothing saved: the All articles segment is empty.
    var seedWithoutArticles: UITestReadingListsSeed {
        UITestReadingListsSeed(readingLists: seed.readingLists, articles: [])
    }

    /// Only the saved articles, in no list: the Reading lists segment is empty.
    var seedWithoutLists: UITestReadingListsSeed {
        UITestReadingListsSeed(
            readingLists: [],
            articles: seed.articles.map { .init(title: $0.title, description: $0.description, snippet: $0.snippet, savedMinutesAgo: $0.savedMinutesAgo, readingListNames: []) }
        )
    }

    var allArticleTitles: [String] {
        seed.articles.map { $0.title }
    }

    var allArticlesByRecentlyAdded: [String] {
        [Self.latestArticleTitle, Self.accentedArticleTitle, Self.lowercaseArticleTitle, openableArticleTitle]
    }

    /// Localized, case- and accent-insensitive order. In Hebrew the device's own script sorts first.
    let allArticlesByTitle: [String]

    var firstListArticlesByRecentlyAdded: [String] {
        [Self.latestArticleTitle, Self.accentedArticleTitle, Self.lowercaseArticleTitle]
    }

    /// Localized, case- and accent-insensitive order. The same in every fixture language.
    var firstListArticlesByTitle: [String] {
        [Self.lowercaseArticleTitle, Self.accentedArticleTitle, Self.latestArticleTitle]
    }

    var readingListNames: [String] {
        seed.readingLists.map { $0.name }
    }

    var readingListsByRecentlyAdded: [String] {
        [Self.accentedListName, Self.lowercaseListName, Self.firstListName]
    }

    var readingListsByTitle: [String] {
        [Self.lowercaseListName, Self.accentedListName, Self.firstListName]
    }

    static func fixture(languageCode: String) -> SavedFixture? {
        switch languageCode {
        case "en":
            return SavedFixture(
                openableArticleTitle: "Dog",
                labels: Labels(allArticlesScope: "All articles", readingListsScope: "Reading lists", sort: "Sort", sortByTitle: "Title", sortByRecentlyAdded: "Recently added", edit: "Edit", cancel: "Cancel", unsave: "Unsave", delete: "Delete", removeFromSaved: "Remove from saved", createNewList: "Create a new list"),
                allArticlesByTitle: ["apple", "Dog", "Émile Zola", "Zebra"]
            )
        case "de":
            return SavedFixture(
                openableArticleTitle: "Haushund",
                labels: Labels(allArticlesScope: "Alle Artikel", readingListsScope: "Sammlungen", sort: "Sortieren", sortByTitle: "Titel", sortByRecentlyAdded: "Kürzlich hinzugefügt", edit: "Bearbeiten", cancel: "Abbrechen", unsave: "Löschen", delete: "Löschen", removeFromSaved: "Von gespeichert entfernen", createNewList: "Eine neue Liste erstellen"),
                allArticlesByTitle: ["apple", "Émile Zola", "Haushund", "Zebra"]
            )
        case "he":
            return SavedFixture(
                openableArticleTitle: "כלב הבית",
                labels: Labels(allArticlesScope: "כל הערכים", readingListsScope: "רשימות קריאה", sort: "מיון", sortByTitle: "כותרת", sortByRecentlyAdded: "נוספו לאחרונה", edit: "עריכה", cancel: "ביטול", unsave: "ביטול שמירה", delete: "מחיקה", removeFromSaved: "להסיר משמורים", createNewList: "יצירת רשימה חדשה"),
                allArticlesByTitle: ["כלב הבית", "apple", "Émile Zola", "Zebra"]
            )
        case "vi":
            return SavedFixture(
                openableArticleTitle: "Chó",
                labels: Labels(allArticlesScope: "Tất cả các bài", readingListsScope: "Danh sách đọc", sort: "Sắp xếp", sortByTitle: "Tựa đề", sortByRecentlyAdded: "Thêm gần đây", edit: "Sửa đổi", cancel: "Hủy bỏ", unsave: "Bỏ lưu", delete: "Xóa", removeFromSaved: "Xóa khỏi Đã lưu", createNewList: "Tạo danh sách mới"),
                allArticlesByTitle: ["apple", "Chó", "Émile Zola", "Zebra"]
            )
        default:
            return nil
        }
    }
}
