//
//  WMFMantleJSONResponseSerializer.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFApiJsonResponseSerializer.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFMantleJSONResponseSerializer : WMFApiJsonResponseSerializer

+ (instancetype)serializerForInstancesOf:(Class)model fromKeypath:(NSString*)keypath;

+ (instancetype)serializerForCollectionsOf:(Class)model fromKeypath:(NSString*)keypath;

@end

NS_ASSUME_NONNULL_END
