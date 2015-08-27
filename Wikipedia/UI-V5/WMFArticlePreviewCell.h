
#import "WMFShadowCell.h"
@class MWKImage;
@class MWKSite;

@interface WMFArticlePreviewCell : WMFShadowCell

@property (copy, nonatomic) NSURL* imageURL;
@property (copy, nonatomic) MWKImage* image;

@property (copy, nonatomic) NSString* titleText;
@property (copy, nonatomic) NSString* descriptionText;

- (void)setSummaryHTML:(NSString*)summaryHTML fromSite:(MWKSite*)site;

- (void)setSummaryAttributedText:(NSAttributedString*)summaryAttributedText;

@end
