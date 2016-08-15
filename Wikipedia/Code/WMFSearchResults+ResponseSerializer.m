//
//  WMFSearchResults+ResponseSerializer.m
//
//
//  Created by Brian Gerstle on 10/28/15.
//
//

#import "WMFSearchResults+ResponseSerializer.h"
#import "WMFMantleJSONResponseSerializer.h"
#import <AFNetworking/AFURLResponseSerialization.h>

@implementation WMFSearchResults (ResponseSerializer)

+ (AFHTTPResponseSerializer *)responseSerializer {
    return [WMFMantleJSONResponseSerializer serializerForInstancesOf:self fromKeypath:@"query"];
}

@end
