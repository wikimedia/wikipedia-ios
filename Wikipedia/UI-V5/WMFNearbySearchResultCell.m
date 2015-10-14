
#import "WMFNearbySearchResultCell.h"
#import "WMFSaveableTitleCollectionViewCell+Subclass.h"

// Views
#import "WMFCompassView.h"

// Frameworks
#import "Wikipedia-Swift.h"
#import <Masonry/Masonry.h>

// Models
#import "WMFSearchResultDistanceProvider.h"
#import "WMFSearchResultBearingProvider.h"
#import "MWKTitle.h"

// Utils
#import "WMFMath.h"
#import "NSString+WMFDistance.h"


static CGFloat const WMFTextPadding    = 8.0;
static CGFloat const WMFDistanceHeight = 20.0;

static CGFloat const WMFImageSize    = 104;
static CGFloat const WMFImagePadding = 8.0;

@interface WMFNearbySearchResultCell ()

// Views
@property (strong, nonatomic) IBOutlet WMFCompassView* compassView;
@property (strong, nonatomic) IBOutlet UIView* distanceLabelBackground;
@property (strong, nonatomic) IBOutlet UILabel* distanceLabel;

// Values
@property (nonatomic, copy) NSString* searchResultDescription;
@property (strong, nonatomic) WMFSearchResultBearingProvider* bearingProvider;
@property (strong, nonatomic) WMFSearchResultDistanceProvider* distanceProvider;

@end

@implementation WMFNearbySearchResultCell

- (void)configureImageViewWithPlaceholder {
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.image = [UIImage imageNamed:@"logo-placeholder-nearby.png"];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self setSearchResultDescription:nil];
    self.distanceProvider = nil;
    self.bearingProvider  = nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.imageView.image                            = [UIImage imageNamed:@"logo-placeholder-nearby.png"];
    self.imageView.layer.cornerRadius               = self.imageView.bounds.size.width / 2;
    self.imageView.layer.borderWidth                = 1.0 / [UIScreen mainScreen].scale;
    self.imageView.layer.borderColor                = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
    self.distanceLabelBackground.layer.cornerRadius = 2.0;
}

- (UICollectionViewLayoutAttributes*)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes*)layoutAttributes {
    self.titleLabel.preferredMaxLayoutWidth = layoutAttributes.size.width - WMFImageSize - WMFImagePadding - WMFImagePadding;
    UICollectionViewLayoutAttributes* preferredAttributes = [layoutAttributes copy];
    CGFloat height                                        = MAX(120, self.titleLabel.intrinsicContentSize.height + WMFTextPadding + WMFTextPadding + WMFDistanceHeight + WMFTextPadding);
    preferredAttributes.size = CGSizeMake(layoutAttributes.size.width, height);
    return preferredAttributes;
}

#pragma mark - Compass

- (void)setBearingProvider:(WMFSearchResultBearingProvider*)bearingProvider {
    [self.KVOController unobserve:_bearingProvider];
    _bearingProvider = bearingProvider;
    if (_bearingProvider) {
        self.compassView.hidden = NO;
        [self.KVOController observe:_bearingProvider
                            keyPath:WMF_SAFE_KEYPATH(_bearingProvider, bearingToLocation)
                            options:NSKeyValueObservingOptionInitial
                              block:^(WMFNearbySearchResultCell* cell,
                                      WMFSearchResultBearingProvider* provider,
                                      NSDictionary* change) {
            [cell setBearing:provider.bearingToLocation];
        }];
    } else {
        self.compassView.hidden = YES;
    }
}

- (void)setBearing:(CLLocationDegrees)bearing {
    self.compassView.angleRadians = DEGREES_TO_RADIANS(bearing);
}

#pragma mark - Title/Description

- (void)setSearchResultDescription:(NSString*)searchResultDescription {
    if (WMF_EQUAL(self.searchResultDescription, isEqualToString:, searchResultDescription)) {
        return;
    }
    _searchResultDescription = [searchResultDescription copy];
    [self updateTitleLabel];
}

- (void)updateTitleLabel {
    NSMutableAttributedString* attributedTitleAndDescription = [NSMutableAttributedString new];

    NSAttributedString* titleText = [self attributedTitleText];
    if ([titleText length] > 0) {
        [attributedTitleAndDescription appendAttributedString:titleText];
    }

    NSAttributedString* searchResultDescription = [self attributedDescriptionText];
    if ([searchResultDescription length] > 0) {
        [attributedTitleAndDescription appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
        [attributedTitleAndDescription appendAttributedString:searchResultDescription];
    }

    self.titleLabel.attributedText = attributedTitleAndDescription;
}

- (NSAttributedString*)attributedTitleText {
    if ([self.title.text length] == 0) {
        return nil;
    }

    return [[NSAttributedString alloc] initWithString:self.title.text attributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:17.0f],
                NSForegroundColorAttributeName: [UIColor blackColor]
            }];
}

- (NSAttributedString*)attributedDescriptionText {
    if ([self.searchResultDescription length] == 0) {
        return nil;
    }

    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacingBefore = 2.0;

    return [[NSAttributedString alloc] initWithString:self.searchResultDescription attributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                NSForegroundColorAttributeName: [UIColor grayColor],
                NSParagraphStyleAttributeName: paragraphStyle
            }];
}

#pragma mark - Distance

- (void)setDistanceProvider:(WMFSearchResultDistanceProvider*)distanceProvider {
    [self.KVOController unobserve:_distanceProvider];
    _distanceProvider = distanceProvider;
    if (_distanceProvider) {
        [self.KVOController observe:_distanceProvider
                            keyPath:WMF_SAFE_KEYPATH(_distanceProvider, distanceToUser)
                            options:NSKeyValueObservingOptionInitial
                              block:^(WMFNearbySearchResultCell* cell,
                                      WMFSearchResultDistanceProvider* provider,
                                      NSDictionary* change) {
            [cell setDistance:provider.distanceToUser];
        }];
    } else {
        [self setDistance:0];
    }
}

- (void)setDistance:(CLLocationDistance)distance {
#if DEBUG && 0
    //   Set ^ to 1 to debug live distance updates by showing the full value
    self.distanceLabel.text = [NSString stringWithFormat:@"%f", distance];
#else
    self.distanceLabel.text = [NSString wmf_localizedStringForDistance:distance];
#endif
}

@end
