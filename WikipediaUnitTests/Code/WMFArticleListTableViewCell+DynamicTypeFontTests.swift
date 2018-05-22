
import XCTest

class WMFArticleCollectionViewCell: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testHighlightFontSizeMatchesNonHighlightFontSizeForAllDynamicTypeSizes() {
        // If a user searches for, say, "fish", we highlight the word "fish" in search result cells by using the custom "WMFFontFamily.systemBold" font.
        // The non-bolded text uses "UIFontTextStyle.body".
        // This test makes sure the font sizes for the bold and non-bold text have same sizes at each dynamic type size.
        // Note: We can't just use the default "UIFontTextStyle.body" and the bold "UIFontTextStyle.headline" because their sizes diverge
        // at the larger dynamic type sizes.
        
        let sizeCategories: [UIContentSizeCategory] = [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]

        for sizeCategory in sizeCategories {
            let traitsForSizeCategory = UITraitCollection(preferredContentSizeCategory:sizeCategory)

            let bodyFontForSizeCategory = UIFont.preferredFont(forTextStyle:UIFontTextStyle.body, compatibleWith:traitsForSizeCategory)
            let systemBoldFontForSizeCategory = UIFont.wmf_font(.semiboldBody, compatibleWithTraitCollection: traitsForSizeCategory)

            XCTAssertTrue(bodyFontForSizeCategory.pointSize == systemBoldFontForSizeCategory.pointSize)
        }
    }
}
