
#import <SSDataSources/SSDataSources.h>

@interface WMFContinueReadingCell : SSBaseCollectionCell
@property (strong, nonatomic) IBOutlet UILabel* title;
@property (strong, nonatomic) IBOutlet UILabel* summary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* leadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* trailingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* topConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* middleConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* bottomConstraint;
@end
