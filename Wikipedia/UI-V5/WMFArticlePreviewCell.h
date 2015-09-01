
#import "WMFShadowCell.h"
@class MWKImage;
@class MWKSite;
@class MWKTitle;

extern CGFloat const WMFArticlePreviewCellTextPadding;
extern CGFloat const WMFArticlePreviewCellImageHeight;

@interface WMFArticlePreviewCell : WMFShadowCell

@property (copy, nonatomic) NSURL* imageURL;
@property (copy, nonatomic) MWKImage* image;

@property (copy, nonatomic) MWKTitle* title;
@property (copy, nonatomic) NSString* descriptionText;

- (void)setSummaryHTML:(NSString*)summaryHTML fromSite:(MWKSite*)site;

- (void)setSummaryAttributedText:(NSAttributedString*)summaryAttributedText;

/**
 *  Get/set style attributes of the label used to display the article's summary.
 *
 *  @warning Do not set the text directly, use `setSummaryHTML:fromSite:` and `setSummaryAttributedText:`.
 *
 *  @return The label used to display the `summaryHTML` and `summaryAttributedText`.
 */
- (UILabel*)summaryLabel;

@end
