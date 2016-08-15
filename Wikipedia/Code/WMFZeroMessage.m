//
//  WMFZeroMessage.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/29/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFZeroMessage.h"
#import "MTLValueTransformer+WMFColorTransformer.h"

@implementation WMFZeroMessage

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
#define WMFZeroMessageKey(key) WMF_SAFE_KEYPATH([WMFZeroMessage new], key)
    return @{ WMFZeroMessageKey(message) : @"message",
              WMFZeroMessageKey(foreground) : @"foreground",
              WMFZeroMessageKey(background) : @"background",
              WMFZeroMessageKey(exitTitle) : @"exitTitle",
              WMFZeroMessageKey(exitWarning) : @"exitWarning",
              WMFZeroMessageKey(partnerInfoText) : @"partnerInfoText",
              WMFZeroMessageKey(partnerInfoUrl) : @"partnerInfoUrl",
              WMFZeroMessageKey(bannerUrl) : @"bannerUrl" };
}

+ (MTLValueTransformer *)foregroundJSONTransformer {
    return [MTLValueTransformer wmf_forwardHexColorTransformer];
}

+ (MTLValueTransformer *)backgroundJSONTransformer {
    return [MTLValueTransformer wmf_forwardHexColorTransformer];
}

@end
