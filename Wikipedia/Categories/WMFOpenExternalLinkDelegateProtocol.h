//  Created by Monte Hurd on 9/24/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.

#import <Foundation/Foundation.h>

@protocol WMFOpenExternalLinkDelegate

- (void)wmf_openExternalUrl:(NSURL*)url;

@end
