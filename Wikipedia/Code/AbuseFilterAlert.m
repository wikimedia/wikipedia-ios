#import "AbuseFilterAlert.h"
#import "PaddedLabel.h"
#import "WikiGlyphLabel.h"
#import "WikiGlyph_Chars.h"
#import "UIColor+WMFStyle.h"
#import "BulletedLabel.h"

typedef NS_ENUM(NSInteger, ViewType) {
    VIEW_TYPE_ICON,
    VIEW_TYPE_HEADING,
    VIEW_TYPE_SUBHEADING,
    VIEW_TYPE_ITEM
};

@interface AbuseFilterAlert ()

@property (nonatomic, strong) NSMutableArray *subViews;

@property (nonatomic, strong) NSMutableArray *subViewData;

@end

@implementation AbuseFilterAlert

- (id)initWithType:(AbuseFilterAlertType)alertType {
    self = [super init];
    if (self) {
        self.subViews = @[].mutableCopy;
        self.subViewData = @[].mutableCopy;
        self.backgroundColor = [UIColor whiteColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self addTopMask];
        _alertType = alertType;
        [self setupSubViewData];
        [self makeSubViews];
        self.minSubviewHeight = 0;
        [self setTabularSubviews:self.subViews];

        // Add just a bit of scrolling margin to bottom just in case the bottom of the last
        // items is near the bottom of the screen.
        self.contentInset = UIEdgeInsetsMake(0, 0, 50, 0);
    }
    return self;
}

- (void)addTopMask {
    // Prevents white bar from appearing above the icon view if user pulls down.
    UIView *topMask = [[UIView alloc] init];
    topMask.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];
    topMask.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:topMask];

    NSDictionary *views = @{ @"topMask": topMask };

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[topMask]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:topMask
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:-1000]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:topMask
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:0]];
}

- (void)setupSubViewData {
    [self.subViewData addObject:
                          @{
                              @"type": @(VIEW_TYPE_ICON),
                              @"string": ((self.alertType == ABUSE_FILTER_DISALLOW) ? WIKIGLYPH_X : WIKIGLYPH_FLAG),
                              @"backgroundColor": ((self.alertType == ABUSE_FILTER_DISALLOW) ? [UIColor wmf_red] : [UIColor wmf_orange]),
                              @"fontColor": [UIColor whiteColor],
                              @"baselineOffset": @((self.alertType == ABUSE_FILTER_DISALLOW) ? 8.4 : 5.5)
                          }.mutableCopy];

    UIColor *grayColor = [UIColor wmf_999999];

    switch (self.alertType) {
        case ABUSE_FILTER_WARNING:

            [self.subViewData addObjectsFromArray:
                                  @[
                                     @{
                                         @"type": @(VIEW_TYPE_HEADING),
                                         @"string": WMFLocalizedStringWithDefaultValue(@"abuse-filter-warning-heading", nil, nil, @"This looks like an unconstructive edit, are you sure you want to publish it?", @"Header text for unconstructive edit warning"),
                                         @"backgroundColor": [UIColor whiteColor],
                                         @"fontColor": [UIColor darkGrayColor]
                                     }.mutableCopy,
                                     @{
                                         @"type": @(VIEW_TYPE_SUBHEADING),
                                         @"string": WMFLocalizedStringWithDefaultValue(@"abuse-filter-warning-subheading", nil, nil, @"Your edit may contain one or more of the following:", @"Subheading text for potentially unconstructive edit warning"),
                                         @"backgroundColor": [UIColor whiteColor],
                                         @"fontColor": grayColor
                                     }.mutableCopy,
                                     @{
                                         @"type": @(VIEW_TYPE_ITEM),
                                         @"string": WMFLocalizedStringWithDefaultValue(@"abuse-filter-warning-caps", nil, nil, @"Typing in ALL CAPS", @"Label text for typing in all capitals"),
                                         @"backgroundColor": [UIColor whiteColor],
                                         @"fontColor": grayColor
                                     }.mutableCopy,
                                     @{
                                         @"type": @(VIEW_TYPE_ITEM),
                                         @"string": WMFLocalizedStringWithDefaultValue(@"abuse-filter-warning-blanking", nil, nil, @"Blanking articles or spamming", @"Label text for blanking articles or spamming"),
                                         @"backgroundColor": [UIColor whiteColor],
                                         @"fontColor": grayColor
                                     }.mutableCopy,
                                     @{
                                         @"type": @(VIEW_TYPE_ITEM),
                                         @"string": WMFLocalizedStringWithDefaultValue(@"abuse-filter-warning-irrelevant", nil, nil, @"Irrelevant external links or images", @"Label text for irrelevant external links and images"),
                                         @"backgroundColor": [UIColor whiteColor],
                                         @"fontColor": grayColor
                                     }.mutableCopy,
                                     @{
                                         @"type": @(VIEW_TYPE_ITEM),
                                         @"string": WMFLocalizedStringWithDefaultValue(@"abuse-filter-warning-repeat", nil, nil, @"Repeeeeating characters", @"Label text for repeating characters"),
                                         @"backgroundColor": [UIColor whiteColor],
                                         @"fontColor": grayColor
                                     }.mutableCopy
                                  ]];

            break;
        case ABUSE_FILTER_DISALLOW:

            [self.subViewData addObjectsFromArray:
                                  @[
                                     @{
                                         @"type": @(VIEW_TYPE_HEADING),
                                         @"string": WMFLocalizedStringWithDefaultValue(@"abuse-filter-disallow-heading", nil, nil, @"You cannot publish this edit. Please go back and change it.", @"Header text for disallowed edit warning."),
                                         @"backgroundColor": [UIColor whiteColor],
                                         @"fontColor": [UIColor darkGrayColor]
                                     }.mutableCopy,
                                     @{
                                         @"type": @(VIEW_TYPE_ITEM),
                                         @"string": WMFLocalizedStringWithDefaultValue(@"abuse-filter-disallow-unconstructive", nil, nil, @"An automated filter has identified this edit as potentially unconstructive or a vandalism attempt.", @"Label text for unconstructive edit description"),
                                         @"backgroundColor": [UIColor whiteColor],
                                         @"fontColor": grayColor
                                     }.mutableCopy,
                                     @{
                                         @"type": @(VIEW_TYPE_ITEM),
                                         @"string": WMFLocalizedStringWithDefaultValue(@"abuse-filter-disallow-notable", nil, nil, @"Wikipedia is an encyclopedia and only neutral, notable content belongs here.", @"Label text for notable content description"),
                                         @"backgroundColor": [UIColor whiteColor],
                                         @"fontColor": grayColor
                                     }.mutableCopy
                                  ]];

            break;
        default:
            break;
    }

    for (NSMutableDictionary *viewData in self.subViewData) {
        NSNumber *type = viewData[@"type"];
        switch (type.integerValue) {
            case VIEW_TYPE_ICON:
                viewData[@"topPadding"] = @0;
                viewData[@"bottomPadding"] = @0;
                viewData[@"leftPadding"] = @0;
                viewData[@"rightPadding"] = @0;
                viewData[@"fontSize"] = @((self.alertType == ABUSE_FILTER_DISALLOW) ? 74.0 : 70.0);
                break;
            case VIEW_TYPE_HEADING:
                viewData[@"topPadding"] = @35;
                viewData[@"bottomPadding"] = @15;
                viewData[@"leftPadding"] = @20;
                viewData[@"rightPadding"] = @20;
                viewData[@"lineSpacing"] = @3;
                viewData[@"kearning"] = @0.4;
                viewData[@"font"] = [UIFont boldSystemFontOfSize:23.0];
                break;
            case VIEW_TYPE_SUBHEADING:
                viewData[@"topPadding"] = @0;
                viewData[@"bottomPadding"] = @8;
                viewData[@"leftPadding"] = @20;
                viewData[@"rightPadding"] = @20;
                viewData[@"lineSpacing"] = @2;
                viewData[@"kearning"] = @0;
                viewData[@"font"] = [UIFont systemFontOfSize:16.0];
                break;
            case VIEW_TYPE_ITEM:
                viewData[@"topPadding"] = @0;
                viewData[@"bottomPadding"] = (self.alertType == ABUSE_FILTER_WARNING) ? @8 : @15;
                viewData[@"leftPadding"] = (self.alertType == ABUSE_FILTER_WARNING) ? @30 : @20;
                viewData[@"rightPadding"] = @20;
                viewData[@"lineSpacing"] = @6;
                viewData[@"kearning"] = @0;
                viewData[@"bulletType"] = (self.alertType == ABUSE_FILTER_WARNING) ? @(BULLET_TYPE_ROUND) : @(BULLET_TYPE_NONE);
                viewData[@"font"] = [UIFont systemFontOfSize:16.0];
                break;
            default:
                break;
        }
    }
}

- (void)makeSubViews {
    UINib *bulletedLabelNib = [UINib nibWithNibName:@"BulletedLabel" bundle:nil];

    for (NSDictionary *viewData in self.subViewData) {
        NSNumber *type = viewData[@"type"];
        switch (type.integerValue) {
            case VIEW_TYPE_ICON: {
                UIView *view = [[UIView alloc] init];
                view.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];

                WikiGlyphLabel *label = [[WikiGlyphLabel alloc] init];
                label.translatesAutoresizingMaskIntoConstraints = NO;
                label.textAlignment = NSTextAlignmentCenter;

                label.backgroundColor = viewData[@"backgroundColor"];
                NSNumber *fontSize = viewData[@"fontSize"];
                NSNumber *baselineOffset = viewData[@"baselineOffset"];

                [label setWikiText:viewData[@"string"]
                             color:viewData[@"fontColor"]
                              size:fontSize.floatValue
                    baselineOffset:baselineOffset.floatValue];

                CGFloat iconHeight = 78.0;
                CGFloat topBarHeight = 125.0;
                label.layer.cornerRadius = iconHeight / 2.0;
                label.clipsToBounds = YES;

                [view addSubview:label];

                NSDictionary *views = @{ @"label": label,
                                         @"v1": view };
                NSDictionary *metrics = @{
                    @"iconHeight": @(iconHeight),
                    @"topBarHeight": @(topBarHeight)
                };

                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[v1(topBarHeight)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label(iconHeight)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[label(iconHeight)]"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];

                [view addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                                 attribute:NSLayoutAttributeCenterX
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:view
                                                                 attribute:NSLayoutAttributeCenterX
                                                                multiplier:1
                                                                  constant:0]];

                [view addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:view
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0]];
                [self.subViews addObject:view];
            } break;
            default: {
                BulletedLabel *item =
                    [[bulletedLabelNib instantiateWithOwner:self options:nil] firstObject];

                item.translatesAutoresizingMaskIntoConstraints = NO;
                item.backgroundColor = viewData[@"backgroundColor"];

                NSNumber *topPadding = viewData[@"topPadding"];
                NSNumber *bottomPadding = viewData[@"bottomPadding"];
                NSNumber *leftPadding = viewData[@"leftPadding"];
                NSNumber *rightPadding = viewData[@"rightPadding"];

                NSNumber *bulletType = [viewData objectForKey:@"bulletType"];
                if (bulletType) {
                    item.bulletType = bulletType.integerValue;

                    // Use same top and left padding.
                    item.bulletLabel.padding = UIEdgeInsetsMake(topPadding.floatValue, leftPadding.floatValue, 0, 4);

                    // Zero out left padding because we already have the left padding applied
                    // to the prefixLabel so no longer need it for the titleLabel.
                    leftPadding = @0;

                    UIColor *color = viewData[@"fontColor"];
                    item.bulletColor = color;
                }

                item.titleLabel.padding = UIEdgeInsetsMake(topPadding.floatValue, leftPadding.floatValue, bottomPadding.floatValue, rightPadding.floatValue);

                [self setText:viewData[@"string"] forLabel:item.titleLabel subViewData:viewData];

                [self.subViews addObject:item];
            } break;
        }
    }
}

- (void)setText:(NSString *)text forLabel:(UILabel *)label subViewData:(NSDictionary *)viewData {
    UIFont *font = viewData[@"font"];
    NSNumber *kearning = viewData[@"kearning"];
    NSNumber *lineSpacing = viewData[@"lineSpacing"];
    UIColor *color = viewData[@"fontColor"];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = lineSpacing.floatValue;

    NSDictionary *attributes =
        @{
           NSFontAttributeName: font,
           NSForegroundColorAttributeName: color,
           NSKernAttributeName: kearning,
           NSParagraphStyleAttributeName: paragraphStyle
        };

    label.attributedText =
        [[NSAttributedString alloc] initWithString:text
                                        attributes:attributes];
}

@end
