#import "WMFExploreSectionFooter.h"
#import "UIImage+WMFStyle.h"
#import "Wikipedia-Swift.h"
@import BlocksKitUIKitExtensions;

@interface WMFExploreSectionFooter ()

@property (strong, nonatomic) IBOutlet UIImageView *moreChevronImageView;

@end

@implementation WMFExploreSectionFooter

- (void)awakeFromNib {
    [super awakeFromNib];

    self.clipsToBounds = NO;
    self.moreChevronImageView.image = [UIImage wmf_imageFlippedForRTLLayoutDirectionNamed:@"chevron-right"];
    @weakify(self);
    [self bk_whenTapped:^{
        @strongify(self);
        if (self.whenTapped) {
            self.whenTapped();
        }
    }];
    [self wmf_configureSubviewsForDynamicType];
}

@end
