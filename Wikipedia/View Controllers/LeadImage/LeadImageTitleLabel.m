//  Created by Monte Hurd on 12/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LeadImageTitleLabel.h"
#import "LeadImageTitleAttributedString.h"
#import "UIScreen+Extras.h"

#define PADDING_BOTTOM_WHEN_IMAGE_PRESENT 17
#define PADDING_BOTTOM_WHEN_IMAGE_NOT_PRESENT 8
#define PADDING UIEdgeInsetsMake(16, 16, PADDING_BOTTOM_WHEN_IMAGE_NOT_PRESENT, 16)

@interface LeadImageTitleLabel ()

@property(strong, nonatomic) id rotationObserver;

@end

@implementation LeadImageTitleLabel

- (void)awakeFromNib {
    self.padding = PADDING;

    self.rotationObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* notification) {
        // Update padding on rotation so padding beneath title goes away in landscape.
        [self updatePadding];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.rotationObserver];
}

- (void)setTitle:(NSString*)title
     description:(NSString*)description {
    self.attributedText =
        [LeadImageTitleAttributedString attributedStringWithTitle:title
                                                      description:description];
    [self updatePadding];
}

- (void)updatePadding {
    CGFloat bottomPadding =
        (
            UIInterfaceOrientationIsPortrait([[UIScreen mainScreen] interfaceOrientation])
            &&
            self.imageExists
        )
        ? PADDING_BOTTOM_WHEN_IMAGE_PRESENT : PADDING_BOTTOM_WHEN_IMAGE_NOT_PRESENT;

    self.padding = UIEdgeInsetsMake(PADDING.top, PADDING.left, bottomPadding, PADDING.right);
}

@end
