//  Created by Monte Hurd on 8/8/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NearbyOp.h"
#import "WikipediaAppUtils.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "Defines.h"

@implementation NearbyOp

- (id)initWithLatitude: (CLLocationDegrees)latitude
             longitude: (CLLocationDegrees)longitude
       completionBlock: (void (^)(NSArray *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {

        NSDictionary *parameters =
        @{
          @"action": @"query",
          @"prop": @"coordinates|pageimages",
          @"colimit": @"50",
          @"pithumbsize" : @(SEARCH_THUMBNAIL_WIDTH),
          @"pilimit": @"50",
          @"generator": @"geosearch",
          @"ggscoord": [NSString stringWithFormat:@"%f|%f", latitude, longitude],
          @"ggsradius": @"10000",
          @"ggslimit": @"50",
          @"format": @"json"
          };
        
        self.request =
        [NSURLRequest getRequestWithURL: [NSURL URLWithString:[SessionSingleton sharedInstance].searchApiUrl]
                             parameters: parameters];
        
        __weak NearbyOp *weakSelf = self;
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
        };
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            
            if(weakSelf.isCancelled){
                cancelledBlock(weakSelf.error);
                return;
            }

            //NSLog(@"weakSelf.jsonRetrieved = %@", weakSelf.jsonRetrieved);
            
            // Check for error.
            if(([[weakSelf.jsonRetrieved class] isSubclassOfClass:[NSDictionary class]]) && weakSelf.jsonRetrieved[@"error"]){
                NSMutableDictionary *errorDict = [weakSelf.jsonRetrieved[@"error"] mutableCopy];
                
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Nearby Op" code:001 userInfo:errorDict];
            }

            NSMutableArray *nearbyResults = @[].mutableCopy;
            NSDictionary *jsonDict = (NSDictionary *)weakSelf.jsonRetrieved;
            
            if (jsonDict.count > 0) {
                NSDictionary *pages = jsonDict[@"query"][@"pages"];
                if (pages) {
                    for (NSDictionary *pageId in pages) {
                        NSDictionary *page = pages[pageId];
                        NSArray *coordsArray = page[@"coordinates"];
                        NSDictionary *coords = coordsArray.firstObject;
                        NSNumber *pageId = page[@"pageid"];
                        NSString *pageImage = page[@"pageimage"];
                        NSDictionary *thumbnail = page[@"thumbnail"];
                        NSString *title = page[@"title"];
                        
                        NSMutableDictionary *d = @{}.mutableCopy;
                        if(coords)d[@"coordinates"] = coords;
                        if(pageId)d[@"pageid"] = pageId;
                        if(pageImage)d[@"pageimage"] = pageImage;
                        if(thumbnail)d[@"thumbnail"] = thumbnail;
                        if(title)d[@"title"] = title;
                        
                        [nearbyResults addObject:d];
                    }
                }
            }

            if (nearbyResults.count == 0) {
                NSMutableDictionary *errorDict = @{}.mutableCopy;
                
                errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"nearby-none", nil);
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Nearby Op" code:002 userInfo:errorDict];
            }

            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }
            
            completionBlock(nearbyResults);
        };
    }
    return self;
}

@end
