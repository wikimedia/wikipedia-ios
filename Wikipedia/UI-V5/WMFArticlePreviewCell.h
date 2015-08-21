
#import "SSBaseCollectionCell.h"

@interface WMFArticlePreviewCell : SSBaseCollectionCell

@property (copy, nonatomic) NSURL* imageURL;
@property (copy, nonatomic) NSString* titleText;
@property (copy, nonatomic) NSString* descriptionText;
@property (copy, nonatomic) NSString* summaryText;

@end
