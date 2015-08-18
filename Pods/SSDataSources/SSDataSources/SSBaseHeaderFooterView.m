//
//  SSBaseHeaderFooterView.m
//  ExampleSSDataSources
//
//  Created by Jonathan Hersh on 8/29/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "SSBaseHeaderFooterView.h"

@implementation SSBaseHeaderFooterView

+ (NSString *)identifier {
    return NSStringFromClass(self);
}

- (instancetype)init {
    if ((self = [self initWithReuseIdentifier:[[self class] identifier]])) {
    
    }
  
    return self;
}

@end
