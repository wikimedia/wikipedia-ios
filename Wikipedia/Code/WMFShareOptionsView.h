#import <UIKit/UIKit.h>
@class PaddedLabel;

@interface WMFShareOptionsView : UIView

@property (weak, nonatomic) IBOutlet UIView *cardImageViewContainer;
@property (weak, nonatomic) IBOutlet UIImageView *cardImageView;
@property (weak, nonatomic) IBOutlet PaddedLabel *shareAsCardLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel *shareAsTextLabel;
@property (weak, nonatomic) IBOutlet PaddedLabel *cancelLabel;

@property (nonatomic, weak) NSObject* accessibilityDelegate;

@end
