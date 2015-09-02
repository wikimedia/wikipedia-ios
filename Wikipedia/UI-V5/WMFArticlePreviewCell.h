#import "WMFSaveableTitleCollectionViewCell.h"

@class MWKImage;

extern CGFloat const WMFArticlePreviewCellTextPadding;
extern CGFloat const WMFArticlePreviewCellImageHeight;

@interface WMFArticlePreviewCell : WMFSaveableTitleCollectionViewCell

@property (copy, nonatomic) NSURL* imageURL;

- (void)setImage:(MWKImage*)image;

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
