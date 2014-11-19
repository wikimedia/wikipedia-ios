//  Created by Monte Hurd on 11/12/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchMessageLabel.h"
#import "WMF_Colors.h"
#import "Defines.h"

#define FONT_SIZE (14.0f * MENUS_SCALE_MULTIPLIER)
#define PADDING UIEdgeInsetsMake(10.0f, 10.0f, 0.0f, 10.0f)
#define COLOR_BACKGROUND [UIColor whiteColor]
#define COLOR_TEXT [UIColor grayColor]

@implementation SearchMessageLabel

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.textAlignment = NSTextAlignmentCenter;
        self.font = [UIFont systemFontOfSize:FONT_SIZE];
        self.textColor = COLOR_TEXT;
        self.backgroundColor = COLOR_BACKGROUND;
    }
    return self;
}

-(void)showWithText:(NSString *)text
{
    self.padding = PADDING;
    self.text = text;
}

-(void)hide
{
    self.padding = UIEdgeInsetsMake(0, 0, 0, 0);
    self.text = nil;
}

@end
