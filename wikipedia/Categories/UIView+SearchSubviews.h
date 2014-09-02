//  Created by Monte Hurd on 4/2/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIView (SearchSubviews)

-(id)getFirstSubviewOfClass:(Class)class;

-(NSArray *)getSubviewsOfClass:(Class)class;

@end
