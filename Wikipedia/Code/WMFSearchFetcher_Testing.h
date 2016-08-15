//
//  WMFSearchFetcher_Testing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/21/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFSearchFetcher.h"

@class AFHTTPSessionManager;

@interface WMFSearchFetcher ()

@property(nonatomic, strong) AFHTTPSessionManager *operationManager;

@end
