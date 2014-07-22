//  Created by Monte Hurd on 7/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AbuseFilterAlert.h"
#import "PaddedLabel.h"
#import "Defines.h"
#import "WikiGlyphLabel.h"
#import "WikiGlyph_Chars.h"
#import "WMF_Colors.h"
#import "WikipediaAppUtils.h"

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

- (id)initWithType: (AbuseFilterAlertType) alertType
{
    self = [super init];
    if (self) {
        self.subViews = @[].mutableCopy;
        self.subViewData = @[].mutableCopy;
        self.backgroundColor = [UIColor whiteColor]; //CHROME_COLOR;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _alertType = alertType;
        [self setupSubViewData];
        [self makeSubViews];
        self.minSubviewHeight = 40;
        [self setTabularSubviews:self.subViews];
    }
    return self;
}

-(void) setupSubViewData
{
    [self.subViewData addObject:
     @{
       @"type": @(VIEW_TYPE_ICON),
       @"string": ((self.alertType == ABUSE_FILTER_DISALLOW) ? WIKIGLYPH_X : WIKIGLYPH_FLAG),
       @"backgroundColor": ((self.alertType == ABUSE_FILTER_DISALLOW) ? WMF_COLOR_RED : WMF_COLOR_ORANGE),
       @"fontColor": [UIColor whiteColor],
       @"fontSize": @((self.alertType == ABUSE_FILTER_DISALLOW) ? 74 : 70),
       @"baselineOffset": @((self.alertType == ABUSE_FILTER_DISALLOW) ? 2.0 : 0.0)
       }
     ];
    
    switch (self.alertType) {
        case ABUSE_FILTER_WARNING:
            
            [self.subViewData addObjectsFromArray:
             @[
               @{
                   @"type": @(VIEW_TYPE_HEADING),
                   @"string": MWLocalizedString(@"abuse-filter-warning-heading", nil),
                   @"backgroundColor": [UIColor whiteColor],
                   @"fontColor": [UIColor darkGrayColor],
                   @"fontSize": @(23),
                   @"baselineOffset": @(0)
                   },
               @{
                   @"type": @(VIEW_TYPE_SUBHEADING),
                   @"string": MWLocalizedString(@"abuse-filter-warning-subheading", nil),
                   @"backgroundColor": [UIColor whiteColor],
                   @"fontColor": [UIColor lightGrayColor],
                   @"fontSize": @(16),
                   @"baselineOffset": @(0)
                   },
               @{
                   @"type": @(VIEW_TYPE_ITEM),
                   @"string": MWLocalizedString(@"abuse-filter-warning-caps", nil),
                   @"backgroundColor": [UIColor whiteColor],
                   @"fontColor": [UIColor blackColor],
                   @"fontSize": @(16),
                   @"baselineOffset": @(0)
                   },
               @{
                   @"type": @(VIEW_TYPE_ITEM),
                   @"string": MWLocalizedString(@"abuse-filter-warning-blanking", nil),
                   @"backgroundColor": [UIColor whiteColor],
                   @"fontColor": [UIColor blackColor],
                   @"fontSize": @(16),
                   @"baselineOffset": @(0)
                   },
               @{
                   @"type": @(VIEW_TYPE_ITEM),
                   @"string": MWLocalizedString(@"abuse-filter-warning-irrelevant", nil),
                   @"backgroundColor": [UIColor whiteColor],
                   @"fontColor": [UIColor blackColor],
                   @"fontSize": @(16),
                   @"baselineOffset": @(0)
                   },
               @{
                   @"type": @(VIEW_TYPE_ITEM),
                   @"string": MWLocalizedString(@"abuse-filter-warning-repeat", nil),
                   @"backgroundColor": [UIColor whiteColor],
                   @"fontColor": [UIColor blackColor],
                   @"fontSize": @(16),
                   @"baselineOffset": @(0)
                   }
               ]];
            
            break;
        case ABUSE_FILTER_DISALLOW:
            
            [self.subViewData addObjectsFromArray:
             @[
               @{
                   @"type": @(VIEW_TYPE_HEADING),
                   @"string": MWLocalizedString(@"abuse-filter-disallow-heading", nil),
                   @"backgroundColor": [UIColor whiteColor],
                   @"fontColor": [UIColor darkGrayColor],
                   @"fontSize": @(23),
                   @"baselineOffset": @(0)
                   },
               @{
                   @"type": @(VIEW_TYPE_ITEM),
                   @"string": MWLocalizedString(@"abuse-filter-disallow-unconstructive", nil),
                   @"backgroundColor": [UIColor whiteColor],
                   @"fontColor": [UIColor blackColor],
                   @"fontSize": @(16),
                   @"baselineOffset": @(0)
                   },
               @{
                   @"type": @(VIEW_TYPE_ITEM),
                   @"string": MWLocalizedString(@"abuse-filter-disallow-notable", nil),
                   @"backgroundColor": [UIColor whiteColor],
                   @"fontColor": [UIColor blackColor],
                   @"fontSize": @(16),
                   @"baselineOffset": @(0)
                   }
               ]];
            
            break;
        default:
            break;
    }
}

-(void)makeSubViews
{
    for (NSDictionary *viewData in self.subViewData) {
        NSNumber *type = viewData[@"type"];
        switch (type.integerValue) {
            case VIEW_TYPE_ICON:
            {
                UIView *view = [[UIView alloc] init];
                view.backgroundColor = CHROME_COLOR;
                
                WikiGlyphLabel *label = [[WikiGlyphLabel alloc] init];
                label.translatesAutoresizingMaskIntoConstraints = NO;
                label.textAlignment = NSTextAlignmentCenter;
                
                label.backgroundColor = viewData[@"backgroundColor"];
                NSNumber *fontSize = viewData[@"fontSize"];
                NSNumber *baselineOffset = viewData[@"baselineOffset"];
                
                [label setWikiText: viewData[@"string"]
                             color: viewData[@"fontColor"]
                              size: fontSize.floatValue
                    baselineOffset: baselineOffset.floatValue];
                
                CGFloat iconHeight = 78.0;
                label.layer.cornerRadius = iconHeight / 2.0;
                label.clipsToBounds = YES;
                
                [view addSubview:label];
                
                NSDictionary *views = @{@"label": label, @"v1": view};
                NSDictionary *metrics = @{@"iconHeight": @(iconHeight)};
                
                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"V:[v1(125)]"
                                                                             options: 0
                                                                             metrics: nil
                                                                               views: views]];
                
                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"V:[label(iconHeight)]"
                                                                             options: 0
                                                                             metrics: metrics
                                                                               views: views]];
                
                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat: @"H:[label(iconHeight)]"
                                                                             options: 0
                                                                             metrics: metrics
                                                                               views: views]];
                
                [view addConstraint: [NSLayoutConstraint constraintWithItem: label
                                                                  attribute: NSLayoutAttributeCenterX
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: view
                                                                  attribute: NSLayoutAttributeCenterX
                                                                 multiplier: 1
                                                                   constant: 0]];
                
                [view addConstraint: [NSLayoutConstraint constraintWithItem: label
                                                                  attribute: NSLayoutAttributeCenterY
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: view
                                                                  attribute: NSLayoutAttributeCenterY
                                                                 multiplier: 1
                                                                   constant: 0]];
                [self.subViews addObject:view];
            }
                break;
            default:
            {
                PaddedLabel *label = [[PaddedLabel alloc] init];
                label.numberOfLines = 0;
                label.lineBreakMode = NSLineBreakByWordWrapping;
                label.translatesAutoresizingMaskIntoConstraints = NO;
                label.backgroundColor = viewData[@"backgroundColor"];
                
                CGFloat nonHeadingBottomSpacing = (self.alertType == ABUSE_FILTER_DISALLOW) ? 22 : 8;
                
                label.padding = (type.integerValue == VIEW_TYPE_HEADING) ?
                    UIEdgeInsetsMake(21, 22, 21, 16)
                    :
                    UIEdgeInsetsMake(8, 22, nonHeadingBottomSpacing, 16);
                
                [self setText:MWLocalizedString(viewData[@"string"], nil) forLabel:label subViewData:viewData];
                
                [self.subViews addObject:label];
            }
                break;
        }
    }
}

-(void)setText:(NSString *)text forLabel:(UILabel *)label subViewData:(NSDictionary *)viewData
{
    
    NSNumber *type = viewData[@"type"];
    NSNumber *size = viewData[@"fontSize"];
    UIColor *color =  viewData[@"fontColor"];
    UIFont *font = (type.integerValue == VIEW_TYPE_HEADING) ?
        [UIFont boldSystemFontOfSize:size.floatValue]
        :
        [UIFont systemFontOfSize:size.floatValue];
    NSNumber *offset = viewData[@"baselineOffset"];

    CGFloat kearning = 0.0;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];

    switch (type.integerValue) {
        case VIEW_TYPE_HEADING:
            paragraphStyle.lineSpacing = 3;
            kearning = 0.4;
            break;
        case VIEW_TYPE_SUBHEADING:
            paragraphStyle.lineSpacing = 2;
            kearning = 0.0;
            break;
        default:
            paragraphStyle.lineSpacing = 6;
            kearning = 0.0;
            break;
    }

    NSDictionary *attributes =
    @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName : color,
        NSBaselineOffsetAttributeName: offset,
        NSKernAttributeName : @(kearning),
        NSParagraphStyleAttributeName : paragraphStyle
      };
    
    label.attributedText =
    [[NSAttributedString alloc] initWithString: text
                                    attributes: attributes];
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
