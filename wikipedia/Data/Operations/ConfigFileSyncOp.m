//  Created by Monte Hurd on 5/8/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ConfigFileSyncOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "NSURLRequest+DictionaryRequest.h"

#import "BundledJson.h"
#import "BundledPaths.h"

@implementation ConfigFileSyncOp

- (id)initForBundledJsonFile: (BundledJsonFile)file
                      maxAge: (CGFloat)maxAge
{
    self = [super init];
    if (self) {

        self.request = [NSURLRequest getRequestWithURL: [BundledPaths bundledJsonFileRemoteUrl:file]
                                            parameters: nil];
        
        __weak ConfigFileSyncOp *weakSelf = self;
        self.aboutToStart = ^{
            
            // Cancel the operation if the existing file hasn't aged enough.
            BOOL shouldRefresh = [BundledJson isRefreshNeededForBundledJsonFile:file maxAge:maxAge];

            if (!shouldRefresh) {
                [weakSelf cancel];
                return;
            }

            [[MWNetworkActivityIndicatorManager sharedManager] push];
        };
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            
            if(weakSelf.isCancelled){
                return;
            }
            
            if (weakSelf.error) {
                return;
            }

            // If it got this far, then a refresh was needed and has completed.
            if (weakSelf.dataRetrieved) {
                NSString *jsonString = [[NSString alloc] initWithData:weakSelf.dataRetrieved encoding:NSUTF8StringEncoding];
                //NSLog(@"jsonString = %@", jsonString);
                if (!jsonString) return;
                NSString *filePath = [BundledPaths bundledJsonFilePath:file];
                NSError *error = nil;
                [jsonString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
            }
        };
    }
    return self;
}

@end
