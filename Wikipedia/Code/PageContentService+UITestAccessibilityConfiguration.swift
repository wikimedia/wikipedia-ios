import Foundation

#if TEST || UITEST
extension PageContentService {
    enum UITestAccessibilityConfiguration {
        struct Script: Encodable, Sendable {
            let labels: Labels
            let localizedTargets: [String: LocalizedTarget]
            let localizedStrings: LocalizedStrings
        }

        struct Labels: Encodable, Sendable {
            let articleLink: String
            let nonLeadImage: String
            let quickFactsTable: String
            let quickFactsTableItem: String
            let aboutThisArticleItem: String
            let licenseLink: String
            let protectedEditIcon: String
            let unprotectedEditIcon: String
        }

        struct LocalizedTarget: Encodable, Sendable {
            let articleHref: String
            let articleTitle: String
            let nonLeadImageHref: String
            let articleLinkInQuickFacts: Bool
        }

        struct LocalizedStrings: Encodable, Sendable {
            let viewEditHistory: String
        }

        static let labels = Labels(
            articleLink: "Article Link Canis",
            nonLeadImage: "Article Non-Lead Image",
            quickFactsTable: "Article Quick Facts Table",
            quickFactsTableItem: "Article Quick Facts Table Link",
            aboutThisArticleItem: "Article About This Article Item",
            licenseLink: "Article License Link",
            protectedEditIcon: "Edit section on protected page",
            unprotectedEditIcon: "Edit section"
        )

        static let localizedTargets: [String: LocalizedTarget] = [
            "en": LocalizedTarget(
                articleHref: "./Canis",
                articleTitle: "Canis",
                nonLeadImageHref: "./File:Dog_morphological_variation.png",
                articleLinkInQuickFacts: false
            ),
            "de": LocalizedTarget(
                articleHref: "./Wolfs-_und_Schakalartige",
                articleTitle: "Wolfs- und Schakalartige",
                nonLeadImageHref: "./Datei:Anatomy_dog.png",
                articleLinkInQuickFacts: true
            ),
            "he": LocalizedTarget(
                articleHref: "./כלב_(סוג)",
                articleTitle: "כלב (סוג)",
                nonLeadImageHref: "./קובץ:CanaanDogChakede1.jpg",
                articleLinkInQuickFacts: true
            ),
            "vi": LocalizedTarget(
                articleHref: "./Chi_Chó",
                articleTitle: "Chi Chó",
                nonLeadImageHref: "./Tập_tin:Mix_breed_dog.jpg",
                articleLinkInQuickFacts: false
            )
        ]

        static let localizedStrings = LocalizedStrings(viewEditHistory: "View edit history")

        static let script = Script(
            labels: labels,
            localizedTargets: localizedTargets,
            localizedStrings: localizedStrings
        )
    }
}
#endif
