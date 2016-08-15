//
//  WMFSearchResults+ResponseSerializer.h
//
//
//  Created by Brian Gerstle on 10/28/15.
//
//

#import "WMFSearchResults.h"
@class AFHTTPResponseSerializer;

@interface WMFSearchResults (ResponseSerializer)

+ (AFHTTPResponseSerializer *)responseSerializer;

@end
