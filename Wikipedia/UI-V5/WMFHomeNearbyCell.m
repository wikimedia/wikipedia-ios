
#import "WMFHomeNearbyCell.h"
#import "WMFSaveableTitleCollectionViewCell+Subclass.h"
#import "WMFCompassView.h"

#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

#import <Masonry/Masonry.h>

static CGFloat const WMFTextPadding    = 8.0;
static CGFloat const WMFDistanceHeight = 20.0;

static CGFloat const WMFImageSize    = 104;
static CGFloat const WMFImagePadding = 8.0;

@interface WMFHomeNearbyCell ()

@property (strong, nonatomic) IBOutlet WMFCompassView* compassView;
@property (strong, nonatomic) IBOutlet UIView* distanceLabelBackground;
@property (strong, nonatomic) IBOutlet UILabel* distanceLabel;

@end

@implementation WMFHomeNearbyCell

- (void)prepareForReuse {
    [super prepareForReuse];
    [[WMFImageController sharedInstance] cancelFetchForURL:self.imageURL];
    self.imageView.image = [UIImage imageNamed:@"logo-placeholder-nearby.png"];
    _distanceLabel.text  = nil;
    self.descriptionText     = nil;
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

- (void)setDescriptionText:(NSString*)descriptionText {
    if (WMF_EQUAL(self.descriptionText, isEqualToString:, descriptionText)) {
        return;
    }
    _descriptionText = [descriptionText copy];
    [self updateTitleLabel];
}

- (void)setDistance:(CLLocationDistance)distance {
    _distance               = distance;
    self.distanceLabel.text = [self textForDistance:distance];
}

- (void)setHeadingAngle:(NSNumber*)headingAngle {
    _headingAngle          = headingAngle;
    self.compassView.angle = headingAngle;
}

- (void)updateTitleLabel {
    NSMutableAttributedString* text = [NSMutableAttributedString new];

    NSAttributedString* titleText = [self attributedTitleText];
    if ([titleText length] > 0) {
        [text appendAttributedString:titleText];
    }

    NSAttributedString* descriptionText = [self attributedDescriptionText];
    if ([descriptionText length] > 0) {
        [text appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
        [text appendAttributedString:descriptionText];
    }

    self.titleLabel.attributedText = text;
}

- (NSAttributedString*)attributedTitleText {
    if ([self.title.text length] == 0) {
        return nil;
    }

    return [[NSAttributedString alloc] initWithString:self.title.text attributes:
            @{
                NSFontAttributeName: [UIFont systemFontOfSize:17.0f],
                NSForegroundColorAttributeName: [UIColor blackColor]
            }];
}

- (NSAttributedString*)attributedDescriptionText {
    if ([self.descriptionText length] == 0) {
        return nil;
    }

    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacingBefore = 2.0;

    return [[NSAttributedString alloc] initWithString:self.descriptionText attributes:
            @{
                NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                NSForegroundColorAttributeName: [UIColor grayColor],
                NSParagraphStyleAttributeName: paragraphStyle
            }];
}

- (NSString*)textForDistance:(CLLocationDistance)distance {
    // Make nearby use feet for meters according to locale.
    // stringWithFormat float decimal places: http://stackoverflow.com/a/6531587

    BOOL useMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];

    if (useMetric) {
        // Show in km if over 0.1 km.
        if (distance > (999.0f / 10.0f)) {
            NSNumber* displayDistance   = @(distance / 1000.0f);
            NSString* distanceIntString = [NSString stringWithFormat:@"%.2f", displayDistance.floatValue];
            return [MWLocalizedString(@"nearby-distance-label-km", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                  withString:distanceIntString];
            // Show in meters if under 0.1 km.
        } else {
            NSString* distanceIntString = [NSString stringWithFormat:@"%.f", distance];
            return [MWLocalizedString(@"nearby-distance-label-meters", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                      withString:distanceIntString];
        }
    } else {
        // Meters to feet.
        distance = distance * 3.28084f;

        // Show in miles if over 0.1 miles.
        if (distance > (5279.0f / 10.0f)) {
            NSNumber* displayDistance   = @(distance / 5280.0f);
            NSString* distanceIntString = [NSString stringWithFormat:@"%.2f", displayDistance.floatValue];
            return [MWLocalizedString(@"nearby-distance-label-miles", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                     withString:distanceIntString];
            // Show in feet if under 0.1 miles.
        } else {
            NSString* distanceIntString = [NSString stringWithFormat:@"%.f", distance];
            return [MWLocalizedString(@"nearby-distance-label-feet", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                    withString:distanceIntString];
        }
    }
}

@end
