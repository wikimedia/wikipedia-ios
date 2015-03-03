//  Created by Brion on 3/12/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface MWLanguageInfo : NSObject

@property (copy) NSString* code;
@property (copy) NSString* dir;

+ (MWLanguageInfo*)languageInfoForCode:(NSString*)code;
+ (BOOL)articleLanguageIsRTL:(MWKArticle*)article;

@end
