//
//  NSDictionary+WMFCommonParams.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (WMFCommonParams)

+ (instancetype)wmf_titlePreviewRequestParameters;

+ (instancetype)wmf_titlePreviewRequestParametersWithExtractLength:(NSUInteger)extractLength
                                                        imageWidth:(NSNumber *)imageWidth;

@end
