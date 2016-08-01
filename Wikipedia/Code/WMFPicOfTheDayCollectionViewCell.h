#import "WMFExploreCollectionViewCell.h"

@interface WMFPicOfTheDayCollectionViewCell : WMFExploreCollectionViewCell

/**
 *  Do not use this to set the image url, this is only exposed
 * for animations
 */
@property (nonatomic, strong) IBOutlet UIImageView* potdImageView;

- (void)setImageURL:(NSURL*)imageURL;

- (void)setDisplayTitle:(NSString*)displayTitle;

+ (CGFloat)estimatedRowHeight;

@end
