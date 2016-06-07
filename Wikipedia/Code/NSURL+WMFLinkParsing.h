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

+ (NSURL*)wmf_URLWithDomain:(NSString*)domain language:(NSString* __nullable)language;

+ (NSURL*)wmf_URLWithDomain:(NSString*)domain language:(NSString* __nullable)language title:(NSString*)title fragment:(NSString* __nullable)fragment;

- (NSURL*)wmf_URLWithTitle:(NSString*)title;

- (NSURL*)wmf_URLWithTitle:(NSString*)title fragment:(NSString* __nullable)fragment;

- (NSURL*)wmf_URLWithPath:(NSString*)path isMobile:(BOOL)isMobile;

@property (nonatomic, readonly) BOOL wmf_isInternalLink;

@property (nonatomic, readonly) BOOL wmf_isCitation;

@property (nonatomic, readonly) BOOL wmf_isMobile;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_internalLinkPath;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_domain;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_language;

@property (nonatomic, copy, readonly, nullable) NSString* wmf_title;

@property (nonatomic, copy, readonly, nullable) NSURL* wmf_mobileURL;

@property (nonatomic, copy, readonly, nullable) NSURL* wmf_desktopURL;

@property (nonatomic, readonly) BOOL wmf_isNonStandardURL;

@end

NS_ASSUME_NONNULL_END
