//  Created by Monte Hurd on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSURL+WMFProxyServer.h"
#import "NSURL+WMFExtras.h"

@implementation NSURL (WMFProxyServer)

- (nullable NSURL*)wmf_imageProxyOriginalSrcURL {
    return [NSURL URLWithString:[self wmf_valueForQueryKey:@"originalSrc"]];
}

@end
