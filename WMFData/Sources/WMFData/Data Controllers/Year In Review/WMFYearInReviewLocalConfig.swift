import Foundation

/// TEMPORARY: a local copy of the 2026 `yir` entry of the remote feature config
/// (`commonv1.yir` in `MediaWiki:AppsFeatureConfig.json` on test and `feed/configuration` on
/// production). `WMFYearInReviewDataController.config` uses it only while the
/// `forceYiREntryPoint2026` developer setting is on and the remote config has no 2026 entry.
///
// TODO: Remove this file when the 2026 entry is published on wikifeeds.
enum WMFYearInReviewLocalConfig {

    typealias YearInReview = WMFFeatureConfigResponse.Common.YearInReview

    static let year2026 = YearInReview(
        year: 2026,
        activeStartDateString: "2026-12-02T20:00:00Z",
        activeEndDateString: "2027-02-01T00:00:00Z",
        dataStartDateString: "2026-01-01T00:00:00Z",
        dataEndDateString: "2026-12-01T00:00:00Z",
        // The global stats below are the 2025 production values (checked 2026-09-28), as placeholders until the 2026 values are known.
        languages: 300,
        articles: 65667790,
        savedArticlesApps: 46392587,
        viewsApps: 14085467928,
        editsApps: 1936242,
        editsPerMinute: 324,
        averageArticlesReadPerYear: 335,
        edits: 78952894,
        editsEN: 31004338,
        hoursReadEN: 2376881343,
        yearsReadEN: 270000,
        topReadEN: [
            "Charlie Kirk",
            "Deaths in 2025",
            "Ed Gein",
            "Donald Trump",
            "Pope Leo XIV"
        ],
        topReadPercentages: [
            YearInReview.TopReadPercentage(identifier: "0.01", min: 43740, max: nil),
            YearInReview.TopReadPercentage(identifier: "1", min: 23456, max: 43739),
            YearInReview.TopReadPercentage(identifier: "5", min: 12345, max: 23455),
            YearInReview.TopReadPercentage(identifier: "10", min: 8901, max: 12344),
            YearInReview.TopReadPercentage(identifier: "20", min: 4567, max: 8900),
            YearInReview.TopReadPercentage(identifier: "30", min: 2456, max: 4566),
            YearInReview.TopReadPercentage(identifier: "40", min: 1234, max: 2455),
            YearInReview.TopReadPercentage(identifier: "50", min: 336, max: 1233)
        ],
        bytesAddedEN: 3471067588,
        // Same countries as 2025 (production config, checked 2026-09-25), without the duplicate "BY".
        hideCountryCodes: [
            "RU", "IR", "CN", "HK", "MO", "SA", "CU", "MM", "BY", "EG", "PS",
            "GN", "PK", "KH", "VN", "SD", "AE", "SY", "JO", "VE", "AF"
        ],
        hideDonateCountryCodes: [
            "AE", "AF", "AX", "BY", "CD", "CI", "CU", "FI", "ID", "IQ", "IR", "KP", "KR", "LB", "LY",
            "MM", "PY", "RU", "SA", "SD", "SO", "SS", "SY", "TM", "TR", "UA", "UZ", "XK", "YE", "ZW"
        ]
    )
}
