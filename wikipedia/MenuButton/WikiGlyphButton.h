//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class WikiGlyphLabel;

@interface WikiGlyphButton : UIView

@property (strong, nonatomic) WikiGlyphLabel *label;

@property (strong, nonatomic) UIColor *color;

@property (nonatomic) BOOL enabled;

@end
