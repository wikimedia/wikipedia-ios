#import "WMFSaveableTitleCollectionViewCell.h"

@class MWKImage, MWKSite;

extern CGFloat const WMFArticlePreviewCellTextPadding;
extern CGFloat const WMFArticlePreviewCellImageHeight;

@interface WMFArticlePreviewCell : WMFSaveableTitleCollectionViewCell

/**
 *  Text which describes the @c title associated with the receiver.
 *
 *  Usually set to the title's WikiData description and put in a label below the title.
 */
@property (copy, nonatomic) NSString* descriptionText;

- (void)setSummary:(NSString*)summary;

- (void)setImage:(MWKImage*)image;
- (void)setImageURL:(NSURL*)imageURL;

@end
