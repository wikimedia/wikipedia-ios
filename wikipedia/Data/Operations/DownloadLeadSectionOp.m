//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "DownloadLeadSectionOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "NSString+Extras.h"
#import "NSObject+Extras.h"

@implementation DownloadLeadSectionOp

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
       completionBlock: (void (^)(NSDictionary *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
        self.request = [NSURLRequest getRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:domain]
                                             parameters: @{
                                                           @"action": @"mobileview",
                                                           @"prop": @"sections|text|lastmodified|lastmodifiedby|languagecount|id",
                                                           @"sections": @"0",
                                                           @"sectionprop": @"toclevel|line|anchor|level|number|fromtitle|index",
                                                           @"page": title,
                                                           @"format": @"json"
                                                           }
                        //Reminder: do not set @"onlyrequestedsections": @"1" above.
                        //Need to see keys for the subsequent sections so the "needsRefresh"
                        //value can be left YES until subsequent sections have been retrieved
                        //(if there's more than a single section).

                        ];
        __weak DownloadLeadSectionOp *weakSelf = self;
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
        };
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            
            if(weakSelf.isCancelled){
                cancelledBlock(weakSelf.error);
                return;
            }

            // Check for error retrieving section zero data.
            if(weakSelf.jsonRetrieved[@"error"]){
                NSMutableDictionary *errorDict = [weakSelf.jsonRetrieved[@"error"] mutableCopy];
                
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Section Zero Op" code:001 userInfo:errorDict];
            }
            
            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }
            
            //NSLog(@"weakSelf.jsonRetrieved = %@", weakSelf.jsonRetrieved);
            
            NSString *lastmodifiedDateString = weakSelf.jsonRetrieved[@"mobileview"][@"lastmodified"];
            NSDate *lastmodifiedDate = [lastmodifiedDateString getDateFromIso8601DateString];

            NSDictionary *lastmodifiedbyDict = weakSelf.jsonRetrieved[@"mobileview"][@"lastmodifiedby"];
            NSString *lastmodifiedby = @"";
            if (lastmodifiedbyDict && (![lastmodifiedbyDict isNull]) && lastmodifiedbyDict[@"name"]) {
                lastmodifiedby = lastmodifiedbyDict[@"name"];
            }
            if (!lastmodifiedby || [lastmodifiedby isNull]) lastmodifiedby = @"";
            
            NSNumber *languagecount = weakSelf.jsonRetrieved[@"mobileview"][@"languagecount"];
            if (!languagecount || [languagecount isNull]) languagecount = @1;
            
            NSString *redirected = weakSelf.jsonRetrieved[@"mobileview"][@"redirected"];
            if (!redirected || [redirected isNull]) redirected = @"";
            
            NSArray *sections = weakSelf.jsonRetrieved[@"mobileview"][@"sections"];

            NSNumber *articleId = weakSelf.jsonRetrieved[@"mobileview"][@"id"];
            if (!articleId || [articleId isNull]) articleId = @0;
            
            completionBlock(@{
                              @"sections": sections,
                              @"lastmodified": lastmodifiedDate,
                              @"lastmodifiedby": lastmodifiedby,
                              @"redirected": redirected,
                              @"languagecount": languagecount,
                              @"articleId": articleId
                              }.mutableCopy);
        };
    }
    return self;
}

@end
