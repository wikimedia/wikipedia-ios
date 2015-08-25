
#import "WMFShadowCell.h"
@class MWKImage;

@interface WMFArticlePreviewCell : WMFShadowCell

@property (copy, nonatomic) NSURL* imageURL;
@property (copy, nonatomic) MWKImage* image;

@property (copy, nonatomic) NSString* titleText;
@property (copy, nonatomic) NSString* descriptionText;
@property (copy, nonatomic) NSAttributedString* summaryAttributedText;

@end
