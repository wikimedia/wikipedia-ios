//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PaddedLabel.h"

@interface WikiGlyphLabel : PaddedLabel

- (void)setWikiText:(NSString*)text color:(UIColor*)color size:(CGFloat)size baselineOffset:(CGFloat)baselineOffset;

@property(nonatomic, strong, readonly) UIColor* color;
@property(nonatomic, readonly) CGFloat size;
@property(nonatomic, readonly) CGFloat baselineOffset;

@end
