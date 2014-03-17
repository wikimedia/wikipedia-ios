//
//  MWLanguageInfo.h
//  Wikipedia-iOS
//
//  Created by Brion on 3/12/14.
//  Copyright (c) 2014 Wikimedia Foundation. Few rights reserved.
//

#import <Foundation/Foundation.h>

@interface MWLanguageInfo : NSObject

@property (copy) NSString *code;
@property (copy) NSString *dir;

+ (MWLanguageInfo *)languageInfoForCode:(NSString *)code;

@end
