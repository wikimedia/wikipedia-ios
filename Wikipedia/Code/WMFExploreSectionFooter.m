#import "WMFExploreSectionFooter.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIImage+WMFStyle.h"

@interface WMFExploreSectionFooter ()

@property(strong, nonatomic) IBOutlet UIImageView *moreChevronImageView;

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
}

@end
