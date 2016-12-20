#import "WMFExploreSectionFooter.h"
#import "UIImage+WMFStyle.h"
#import "Wikipedia-Swift.h"

@interface WMFExploreSectionFooter ()

@property (strong, nonatomic) IBOutlet UIImageView *moreChevronImageView;

@end

@implementation WMFExploreSectionFooter

- (void)awakeFromNib {
    [super awakeFromNib];

    self.clipsToBounds = NO;
    self.moreChevronImageView.image = [UIImage wmf_imageFlippedForRTLLayoutDirectionNamed:@"chevron-right"];
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self wmf_configureSubviewsForDynamicType];
    [self addGestureRecognizer:tapGR];
}

- (void)handleTapGesture:(UIGestureRecognizer *)tapGR {
    if (tapGR.state != UIGestureRecognizerStateRecognized) {
        return;
    }
    if (self.whenTapped) {
        self.whenTapped();
    }
}

@end
