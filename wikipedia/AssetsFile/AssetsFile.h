//  Created by Monte Hurd on 5/9/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AssetsFileEnum.h"
#import <UIKit/UIKit.h>

@interface AssetsFile : NSObject

@property (nonatomic, readonly) AssetsFileEnum file;

@property (nonatomic, retain, readonly) NSString* path;

@property (nonatomic, retain, readonly) NSArray* array;

@property (nonatomic, retain, readonly) NSDictionary* dictionary;

@property (nonatomic, retain, readonly) NSURL* url;

- (id)initWithFile:(AssetsFileEnum)file;

- (BOOL)isOlderThan:(CGFloat)maxAge;

@end
