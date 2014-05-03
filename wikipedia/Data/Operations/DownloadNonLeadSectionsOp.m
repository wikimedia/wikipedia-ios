//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "DownloadNonLeadSectionsOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "NSString+Extras.h"

@implementation DownloadNonLeadSectionsOp

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
       completionBlock: (void (^)(NSArray *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
        self.request = [NSURLRequest getRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:domain]
                                             parameters: @{
                                                           @"action": @"mobileview",
                                                           @"prop": @"sections|text",
                                                           @"sections": @"1-",
                                                           @"onlyrequestedsections": @"1",
                                                           @"sectionprop": @"toclevel|line|anchor|level|number|fromtitle|index",
                                                           @"page": title,
                                                           @"format": @"json"
                                                           }
                        ];
        __weak DownloadNonLeadSectionsOp *weakSelf = self;
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
                weakSelf.error = [NSError errorWithDomain:@"Section Non Zero Op" code:001 userInfo:errorDict];
            }

            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }

            NSArray *sections = weakSelf.jsonRetrieved[@"mobileview"][@"sections"];

            NSMutableArray *output = @[].mutableCopy;
            
            // The fromtitle tells us if a section was transcluded, but the api sometimes returns false instead
            // of just leaving it out if the section wasn't transcluded. It is also sometimes the name of the
            // current article, which is redundant. So here remove the fromtitle key/value in both of these
            // cases. That way the existense of a "fromtitle" can be relied on as a true transclusion indicator.
            // Todo: pull this out into own method within this file.
            for (NSDictionary *section in sections) {
                NSMutableDictionary *mutableSection = section.mutableCopy;
                if ([mutableSection[@"fromtitle"] isKindOfClass:[NSString class]]) {
                    NSString *fromTitle = mutableSection[@"fromtitle"];
                    if ([[title cleanWikiTitle] isEqualToString:[fromTitle cleanWikiTitle]]) {
                        [mutableSection removeObjectForKey:@"fromtitle"];
                    }
                }else{
                    [mutableSection removeObjectForKey:@"fromtitle"];
                }
                [output addObject:mutableSection];
            }

            completionBlock(output);
        };
    }
    return self;
}

@end
