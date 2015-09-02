#import "WMFSaveableTitleCollectionViewCell.h"

@class MWKImage;

extern CGFloat const WMFArticlePreviewCellTextPadding;
extern CGFloat const WMFArticlePreviewCellImageHeight;

@interface WMFArticlePreviewCell : WMFSaveableTitleCollectionViewCell

/**
 *  Text which describes the @c title associated with the receiver.
 *
 *  Usually set to the title's WikiData description and put in a label below the title.
 */
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
