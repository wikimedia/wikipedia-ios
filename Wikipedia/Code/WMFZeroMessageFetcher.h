//
//  WMFZeroMessageFetcher.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/29/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWKSite.h"

@interface WMFZeroMessageFetcher : NSObject

- (AnyPromise*)fetchZeroMessageForSite:(MWKSite*)site;

- (void)cancelAllFetches;

@end
