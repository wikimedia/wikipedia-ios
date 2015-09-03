//  Created by Monte Hurd on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "RecentSearchCell.h"
#import "WikiGlyph_Chars.h"
#import "UIFont+WMFStyle.h"
#import "UIView+WMFShadow.h"
#import "UIColor+WMFHexColor.h"

static CGFloat const magnifyIconSize    = 26.f;
static NSInteger const magnifyIconColor = 0x777777;

@interface RecentSearchCell ()

@property (strong, nonatomic) IBOutlet UIView* shadowView;
@property (strong, nonatomic) IBOutlet UILabel* iconLabel;

@end

@implementation RecentSearchCell

- (void)awakeFromNib {
    self.iconLabel.attributedText = [RecentSearchCell attributedIconString];
    [self.shadowView wmf_setupShadow];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.backgroundColor             = [UIColor clearColor];
}

+ (NSAttributedString*)attributedIconString {
    static dispatch_once_t once;
    static NSAttributedString* sharedString;
    dispatch_once(&once, ^{
        sharedString =
            [[NSAttributedString alloc] initWithString:WIKIGLYPH_MAGNIFY_BOLD
                                            attributes:@{
                 NSFontAttributeName: [UIFont wmf_glyphFontOfSize:magnifyIconSize],
                 NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:magnifyIconColor alpha:1.0f],
                 NSBaselineOffsetAttributeName: @1
             }];
    });
    return sharedString;
}

@end
