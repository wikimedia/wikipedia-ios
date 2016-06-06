//
//  NSURL+WMFLinkParsing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (WMFLinkParsing)

- (BOOL)wmf_isInternalLink;

- (BOOL)wmf_isCitation;

- (NSString*)wmf_internalLinkPath;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_domain;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_language;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_title;

@property (nonatomic, copy, readonly, nullable) NSURL* wmf_mobileURL;

+ (NSURL*)wmf_URLWithDomain:(NSString*)domain language:(NSString*)language;

@end

NS_ASSUME_NONNULL_END
