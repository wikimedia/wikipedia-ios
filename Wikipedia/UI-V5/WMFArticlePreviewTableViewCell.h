#import <SSDataSources/SSDataSources.h>

@class MWKTitle;
@class MWKSavedPageList;
@class MWKImage;

@interface WMFArticlePreviewTableViewCell : SSBaseTableCell

@property (nonatomic, strong) NSString* titleText;

@property (nonatomic, strong) NSString* descriptionText;

@property (nonatomic, strong) NSString* snippetText;

- (void)setImage:(MWKImage*)image;
- (void)setImageURL:(NSURL*)imageURL;

/**
 *  Title associated with the receiver.
 *
 *  Setting this property updates both the @c titleLabel and @c saveButton states.
 */
@property (copy, nonatomic) MWKTitle* title;

@property (nonatomic, strong) MWKSavedPageList* savedPageList;

@end
