//  Created by Monte Hurd on 5/8/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SyncAssetsFileOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "NSURLRequest+DictionaryRequest.h"

#import "AssetsFile.h"

@implementation SyncAssetsFileOp

- (id)initForAssetsFile: (AssetsFileEnum)file
                 maxAge: (CGFloat)maxAge
{
    self = [super init];
    if (self) {
    
        AssetsFile *assetsFile = [[AssetsFile alloc] initWithFile:file];
        self.request = [NSURLRequest getRequestWithURL: assetsFile.url
                                            parameters: nil];
        
        __weak SyncAssetsFileOp *weakSelf = self;
        self.aboutToStart = ^{
            
            // Cancel the operation if the existing file hasn't aged enough.
            BOOL shouldRefresh = [assetsFile isOlderThan:maxAge];

            if (!shouldRefresh) {
                [weakSelf cancel];
                return;
            }

            [[MWNetworkActivityIndicatorManager sharedManager] push];
        };
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            
            if (weakSelf.isCancelled || weakSelf.error) return;

            if (weakSelf.response) {
                // Make extra sure that weird responses don't get written.
                if (((NSHTTPURLResponse *)weakSelf.response).statusCode != 200) return;
            }

            // If it got this far, then a refresh was needed and has completed.
            if (weakSelf.dataRetrieved) {
                NSString *jsonString = [[NSString alloc] initWithData:weakSelf.dataRetrieved encoding:NSUTF8StringEncoding];
                //NSLog(@"jsonString = %@", jsonString);
                if (!jsonString || (jsonString.length == 0)) return;
                NSString *filePath = assetsFile.path;
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
