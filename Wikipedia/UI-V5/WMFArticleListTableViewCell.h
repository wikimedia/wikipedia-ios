
#import <SSDataSources/SSDataSources.h>

@interface WMFArticleListTableViewCell : SSBaseTableCell

/**
 *  Label used to display the receiver's @c title.
 *
 *  Configure as needed in Interface Builder or during initialization when subclassing.
 */
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;

/**
 *  Set the receivers @c title, optionally highlighting the a part of the title
 *
 *  @param text          The text of the title
 *  @param highlightText The part of the title to highlight
 */
- (void)updateTitleLabelWithText:(NSString*)text highlightingText:(NSString*)highlightText;

/**
 *  Label used to display the receiver's @c description.
 *
 *  Configure as needed in Interface Builder or during initialization when subclassing.
 */
@property (nonatomic, strong) IBOutlet UILabel* descriptionLabel;

/**
 *  The view used to display the receiver's @c image.
 */
@property (strong, nonatomic) IBOutlet UIImageView* articleImageView;


@end
