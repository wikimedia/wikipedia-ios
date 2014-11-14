//  Created by Monte Hurd on 11/12/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchDidYouMeanButton.h"
#import "NSString+FormattedAttributedString.h"
#import "WMF_Colors.h"

#define FONT_SIZE 14.0f
#define PADDING UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f)
#define COLOR_STRING [UIColor grayColor]
#define COLOR_UNDERLINE [UIColor colorWithWhite:0.8 alpha:1.0]
#define COLOR_TERM WMF_COLOR_BLUE

@implementation SearchDidYouMeanButton

-(void)showWithText:(NSString *)text term:(NSString *)term
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSMutableDictionary *baseAttributes =
    @{
      NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE],
      NSForegroundColorAttributeName: COLOR_STRING,
      NSParagraphStyleAttributeName : paragraphStyle
      }.mutableCopy;
    
    NSMutableDictionary *subAttributes =
    @{
      NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE],
      NSForegroundColorAttributeName: COLOR_TERM
      }.mutableCopy;


    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        baseAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
        baseAttributes[NSUnderlineColorAttributeName] = COLOR_UNDERLINE;

        subAttributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
        subAttributes[NSUnderlineColorAttributeName] = COLOR_UNDERLINE;
    }

    self.padding = PADDING;
    
    self.attributedText =
    [text attributedStringWithAttributes: baseAttributes
                     substitutionStrings: @[term]
                  substitutionAttributes: @[subAttributes]].mutableCopy;
}

-(void)hide
{
    self.padding = UIEdgeInsetsMake(0, 0, 0, 0);
    self.attributedText = nil;
}

@end
