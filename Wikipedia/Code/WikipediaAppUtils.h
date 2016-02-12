//  Created by Adam Baso on 2/13/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NSObjectUtilities.h"
#import "NSString+WMFPageUtilities.h"

NS_ASSUME_NONNULL_BEGIN

WMF_TECH_DEBT_DEPRECATED_MSG("This class is deprecated, its methods should be broken up into separate category methods.")
@interface WikipediaAppUtils : NSObject

+ (NSString*)appVersion;
+ (NSString*)formFactor;
+ (NSString*)versionedUserAgent;
+ (NSString*)languageNameForCode:(NSString*)code;

+ (void)copyAssetsFolderToAppDataDocuments;

@end

NS_ASSUME_NONNULL_END