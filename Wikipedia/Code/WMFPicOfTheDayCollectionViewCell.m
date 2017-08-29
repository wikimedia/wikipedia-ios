#import "WMFPicOfTheDayCollectionViewCell.h"
#import "UIImageView+WMFFaceDetectionBasedOnUIApplicationSharedApplication.h"
#import "WMFGradientView.h"
#import "Wikipedia-Swift.h"

static const NSString *kvo_WMFPicOfTheDayCollectionViewCell_potdImageView_image = nil;

@interface WMFPicOfTheDayCollectionViewCell ()

@property (weak, nonatomic) IBOutlet WMFGradientView *displayTitleBackgroundView;

@property (nonatomic, strong) IBOutlet UILabel *displayTitleLabel;

@end

@implementation WMFPicOfTheDayCollectionViewCell

- (void)dealloc {
    [self.potdImageView removeObserver:self forKeyPath:WMF_SAFE_KEYPATH(self.potdImageView, image) context:&kvo_WMFPicOfTheDayCollectionViewCell_potdImageView_image];
}

+ (CGFloat)estimatedRowHeight {
    return 346.f;
}

- (void)setDisplayTitle:(NSString *)displayTitle {
    self.displayTitleLabel.text = displayTitle;
}

- (void)setImageURL:(NSURL *)imageURL {
    [self.potdImageView wmf_setImageWithURL:imageURL detectFaces:YES failure:WMFIgnoreErrorHandler success:WMFIgnoreSuccessHandler];
}

#pragma mark - UITableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.potdImageView addObserver:self forKeyPath:WMF_SAFE_KEYPATH(self.potdImageView, image) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kvo_WMFPicOfTheDayCollectionViewCell_potdImageView_image];
    if (@available(iOS 11.0, *)) {
        self.potdImageView.accessibilityIgnoresInvertColors = YES;
    }
    [self wmf_configureSubviewsForDynamicType];
}

- (void)prepareForReuse {
    [super awakeFromNib];
    self.displayTitleLabel.text = @"";
    [self.potdImageView wmf_reset];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if (context == &kvo_WMFPicOfTheDayCollectionViewCell_potdImageView_image) {
        BOOL didSetDesiredImage = [self.potdImageView wmf_imageURLToFetch] != nil;
        // whether or not these properties are animated will be determined based on whether or not
        // there was an animation setup when image was set
        self.displayTitleLabel.alpha = didSetDesiredImage ? 1.0 : 0.0;
        self.displayTitleBackgroundView.alpha = self.displayTitleLabel.alpha;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    self.potdImageView.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = theme.colors.midBackground;
    self.potdImageView.alpha = theme.imageOpacity;
}

@end
