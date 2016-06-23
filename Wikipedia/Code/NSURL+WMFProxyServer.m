//  Created by Monte Hurd on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSURL+WMFProxyServer.h"
#import "NSURL+WMFQueryParameters.h"

NSString* const WMFProxyImageOriginalSrcKey = @"originalSrc";
NSString* const WMFProxyImageBasePath = @"imageProxy";
NSString* const WMFProxyFileBasePath = @"fileProxy";

@implementation NSURL (WMFProxyServer)

- (nullable NSURL*)wmf_imageProxyOriginalSrcURL {
    return [NSURL URLWithString:[self wmf_valueForQueryKey:WMFProxyImageOriginalSrcKey]];
}

- (NSURL*)wmf_imageProxyURLWithOriginalSrc:(NSString*)originalSrc {
    return [self wmf_urlWithValue:originalSrc forQueryKey:WMFProxyImageOriginalSrcKey];
}

@end
