//  Created by Monte Hurd on 5/9/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "BundledPathsEnum.h"
#import "BundledJsonEnum.h"

@interface BundledPaths : NSObject

+ (NSString *)bundledJsonFilePath:(BundledJsonFile)file;
+ (NSURL *)bundledJsonFileRemoteUrl:(BundledJsonFile)file;

@end
