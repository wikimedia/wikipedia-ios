#import "SSDataSources.h"
@import WMF;
@class MWKImage;

@interface WMFArticleListTableViewCell : SSBaseTableCell

@property (nonatomic, strong) NSString *titleText;

@property (nonatomic, strong) NSString *descriptionText;

/**
 *  Set the recievers @c image using an MWKImage
 */
- (void)setImage:(MWKImage *)image failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;

/**
 *  Set the recievers @c image using a URL
 */
- (void)setImageURL:(NSURL *)imageURL failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;

/**
 *  Set the recievers @c image using an MWKImage
 */
- (void)setImage:(MWKImage *)image;

/**
 *  Set the recievers @c image using a URL
 */
- (void)setImageURL:(NSURL *)imageURL;

+ (CGFloat)estimatedRowHeight;

@end

/**
 *  Provided for subclasses and categories.
 *  In general you shoud use the methods in the interface above to configure the cell
 */
@interface WMFArticleListTableViewCell (Outlets)

/**
 *  Label used to display the receiver's @c title.
 *
 */
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

/**
 *  Label used to display the receiver's @c description.
 *
 */
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;

/**
 *  The view used to display the receiver's @c image.
 */
@property (strong, nonatomic) IBOutlet UIImageView *articleImageView;

@end
