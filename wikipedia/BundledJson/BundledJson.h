//  Created by Monte Hurd on 5/9/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "BundledPathsEnum.h"
#import "BundledJsonEnum.h"

@interface BundledJson : NSObject

+ (NSDictionary *)dictionaryFromBundledJsonFile:(BundledJsonFile)file;

+ (NSArray *)arrayFromBundledJsonFile:(BundledJsonFile)file;

+ (BOOL)isRefreshNeededForBundledJsonFile:(BundledJsonFile)file maxAge:(CGFloat)maxAge;

@end
