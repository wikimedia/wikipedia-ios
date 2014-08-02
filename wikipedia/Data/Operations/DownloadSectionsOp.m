//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "DownloadSectionsOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "NSString+Extras.h"
#import "NSObject+Extras.h"
#import "ReadingActionFunnel.h"

@implementation DownloadSectionsOp

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
       leadSectionOnly: (BOOL)leadSectionOnly
       completionBlock: (void (^)(NSDictionary *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {

        NSMutableDictionary *params =
        @{
          @"action": @"mobileview",
          @"prop": @"sections|text|lastmodified|lastmodifiedby|languagecount|id|protection|editable",
          @"sectionprop": @"toclevel|line|anchor|level|number|fromtitle|index",
          @"noheadings": @"true",
          @"page": title,
          @"format": @"json"
          }.mutableCopy;
        
        if (!leadSectionOnly) {
            params[@"onlyrequestedsections"] = @"1";
            params[@"sections"] = @"1-";
        }else{

            //Reminder: do not set @"onlyrequestedsections": @"1" for lead section.
            //Need to see keys for the subsequent sections so the "needsRefresh"
            //value can be left YES until subsequent sections have been retrieved
            //(if there's more than a single section).

            params[@"sections"] = @"0";
            
            if ([SessionSingleton sharedInstance].sendUsageReports) {
                ReadingActionFunnel *funnel = [[ReadingActionFunnel alloc] init];
                params[@"appInstallID"] = funnel.appInstallID;
            }
        }
    
        self.request = [NSURLRequest getRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:domain]
                                            parameters: params];
        __weak DownloadSectionsOp *weakSelf = self;
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

                NSString *errorDomain = leadSectionOnly ? @"Section Zero Op" : @"Section Non Zero Op";
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:errorDomain code:001 userInfo:errorDict];
                
            }

            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }





            NSArray *sections = weakSelf.jsonRetrieved[@"mobileview"][@"sections"];

            NSMutableArray *outputSections = @[].mutableCopy;
            
            // The fromtitle tells us if a section was transcluded, but the api sometimes returns false instead
            // of just leaving it out if the section wasn't transcluded. It is also sometimes the name of the
            // current article, which is redundant. So here remove the fromtitle key/value in both of these
            // cases. That way the existense of a "fromtitle" can be relied on as a true transclusion indicator.
            // Todo: pull this out into own method within this file.
            for (NSDictionary *section in sections) {
                NSMutableDictionary *mutableSection = section.mutableCopy;
                if ([mutableSection[@"fromtitle"] isKindOfClass:[NSString class]]) {
                    NSString *fromTitle = mutableSection[@"fromtitle"];
                    if ([[title wikiTitleWithoutUnderscores] isEqualToString:[fromTitle wikiTitleWithoutUnderscores]]) {
                        [mutableSection removeObjectForKey:@"fromtitle"];
                    }
                }else{
                    [mutableSection removeObjectForKey:@"fromtitle"];
                }
                [outputSections addObject:mutableSection];
            }





            NSString *lastmodifiedDateString = weakSelf.jsonRetrieved[@"mobileview"][@"lastmodified"];
            NSDate *lastmodifiedDate = [lastmodifiedDateString getDateFromIso8601DateString];
            if (!lastmodifiedDate || [lastmodifiedDate isNull]) {
                NSLog(@"Bad lastmodified date, will show as recently modified as a workaround");
                lastmodifiedDate = [[NSDate alloc] init];
            }

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
            
            NSNumber *articleId = weakSelf.jsonRetrieved[@"mobileview"][@"id"];
            if (!articleId || [articleId isNull]) articleId = @0;
            
            NSNumber *editable = weakSelf.jsonRetrieved[@"mobileview"][@"editable"];
            if (!editable || [editable isNull]) editable = @NO;
            
            NSString *protectionStatus = @"";
            id protection = weakSelf.jsonRetrieved[@"mobileview"][@"protection"];
            // if empty this can be an array instead of an object/dict!
            // https://bugzilla.wikimedia.org/show_bug.cgi?id=67054
            if (protection && [protection isKindOfClass:[NSDictionary class]]) {
                NSDictionary *protectionDict = (NSDictionary *)protection;
                if (protectionDict[@"edit"] && [protection[@"edit"] count] > 0) {
                    protectionStatus = protectionDict[@"edit"][0];
                }
            }
            if (!protectionStatus || [protectionStatus isNull]) protectionStatus = @"";

            NSMutableDictionary *output = @{
                                            @"sections": outputSections,
                                            @"lastmodified": lastmodifiedDate,
                                            @"lastmodifiedby": lastmodifiedby,
                                            @"redirected": redirected,
                                            @"languagecount": languagecount,
                                            @"articleId": articleId,
                                            @"editable": editable,
                                            @"protectionStatus": protectionStatus
                                            }.mutableCopy;



            completionBlock(output);
        };
    }
    return self;
}

@end
