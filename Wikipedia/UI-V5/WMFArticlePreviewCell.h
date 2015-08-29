
#import "WMFShadowCell.h"
@class MWKImage, MWKTitle;

@interface WMFArticlePreviewCell : WMFShadowCell

@property (copy, nonatomic) NSURL* imageURL;
@property (copy, nonatomic) MWKImage* image;

@property (copy, nonatomic) NSString* titleText;
@property (copy, nonatomic) NSString* descriptionText;
@property (copy, nonatomic) NSAttributedString* summaryAttributedText;

@property (copy, nonatomic) MWKTitle* title;

@end
