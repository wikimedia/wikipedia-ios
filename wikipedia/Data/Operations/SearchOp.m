//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchOp.h"
#import "WikipediaAppUtils.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "Defines.h"
#import "NSString+Extras.h"
#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "NSManagedObjectContext+SimpleFetch.h"

@implementation SearchOp

- (id)initWithSearchTerm: (NSString *)searchTerm
         completionBlock: (void (^)(NSArray *))completionBlock
          cancelledBlock: (void (^)(NSError *))cancelledBlock
              errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {

        NSMutableDictionary *parameters =
        [@{
           @"action": @"query",
           @"generator": @"prefixsearch",
           @"gpssearch": (searchTerm ? searchTerm : @""),
           @"gpsnamespace": @0,
           @"gpslimit": @(SEARCH_MAX_RESULTS),
           @"prop": @"pageimages",
           @"piprop": @"thumbnail",
           @"pithumbsize" : @(SEARCH_THUMBNAIL_WIDTH),
           @"pilimit": @(SEARCH_MAX_RESULTS),
           @"format": @"json"
           } mutableCopy];
        
        self.request = [NSURLRequest getRequestWithURL: [NSURL URLWithString:[SessionSingleton sharedInstance].searchApiUrl]
                                             parameters: parameters
                        ];

        //NSLog(@"self.request = %@", self.request);
        
        __weak SearchOp *weakSelf = self;
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
                weakSelf.error = [NSError errorWithDomain:@"Search Op" code:001 userInfo:errorDict];
            }

            // Make output array contain just dictionaries for each result.
            NSMutableArray *output = @[].mutableCopy;
            NSDictionary *jsonDict = (NSDictionary *)weakSelf.jsonRetrieved;
            if (jsonDict.count > 0) {
                NSDictionary *query = (NSDictionary *)jsonDict[@"query"];
                if (query) {
                    NSDictionary *pages = (NSDictionary *)query[@"pages"];
                    if (pages) {
                        for (NSDictionary *pageId in pages) {

                            // "dictionaryWithDictionary" used because it creates a deep mutable copy of the __NSCFDictionary.
                            NSMutableDictionary *page = [NSMutableDictionary dictionaryWithDictionary:pages[pageId]];

                            if (!page) continue;

                            if (!page[@"thumbnail"]) page[@"thumbnail"] = @{}.mutableCopy;

                            page[@"title"] = page[@"title"] ? [page[@"title"] wikiTitleWithoutUnderscores] : @"";

                            if (page) [output addObject:page];
                        }
                    }
                }
            }
            
            // Sort output array by title.
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"title"
                                                                           ascending: YES];
            NSArray *arraySortedByTitle = [output sortedArrayUsingDescriptors:@[sortDescriptor]];
            output = arraySortedByTitle.mutableCopy;
            
            // Move best match(es) to top of array.
            NSPredicate *p = [NSPredicate predicateWithFormat:@"title LIKE[c] %@", searchTerm];
            NSArray *bestMatches = [output filteredArrayUsingPredicate:p];
            if (bestMatches && (bestMatches.count > 0)) {
                [output removeObjectsInArray:bestMatches];
                NSArray* bestMatchesReversed = [[bestMatches reverseObjectEnumerator] allObjects];
                output = [bestMatchesReversed arrayByAddingObjectsFromArray:output].mutableCopy;
            }

            // If no matches set error.
            if (output.count == 0) {
                NSMutableDictionary *errorDict = @{}.mutableCopy;
                
                errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"search-no-matches", nil);
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Search Op" code:002 userInfo:errorDict];
            }

            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }

            // Prepare placeholder Image records.
            [[ArticleDataContextSingleton sharedInstance].workerContext performBlockAndWait:^(){
                for (NSDictionary *page in output) {
                    // If url thumb found, prepare a core data Image object so URLCache
                    // will know this is an image to intercept.
                    NSDictionary *thumbData = page[@"thumbnail"];
                    if (thumbData) {
                        NSString *src = thumbData[@"source"];
                        NSNumber *height = thumbData[@"height"];
                        NSNumber *width = thumbData[@"width"];
                        if (src && height && width) {
                            [weakSelf insertPlaceHolderImageEntityIntoContext: [ArticleDataContextSingleton sharedInstance].workerContext
                                                              forImageWithUrl: src
                                                                        width: width
                                                                       height: height];
                        }
                    }
                }
                NSError *error = nil;
                [[ArticleDataContextSingleton sharedInstance].workerContext save:&error];
            }];
            
            completionBlock(output);
        };
    }
    return self;
}

#pragma mark Core data Image record placeholder for thumbnail (so they get cached)

-(void)insertPlaceHolderImageEntityIntoContext: (NSManagedObjectContext *)context
                               forImageWithUrl: (NSString *)url
                                         width: (NSNumber *)width
                                        height: (NSNumber *)height
{
    Image *existingImage = (Image *)[context getEntityForName: @"Image" withPredicateFormat:@"sourceUrl == %@", [url getUrlWithoutScheme]];
    // If there's already an image record for this exact url, don't create another one!!!
    if (!existingImage) {
        Image *image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:context];
        image.imageData = [NSEntityDescription insertNewObjectForEntityForName:@"ImageData" inManagedObjectContext:context];
        image.imageData.data = [[NSData alloc] init];
        image.dataSize = @(image.imageData.data.length);
        image.fileName = [url lastPathComponent];
        image.fileNameNoSizePrefix = [image.fileName getWikiImageFileNameWithoutSizePrefix];
        image.extension = [url pathExtension];
        image.imageDescription = nil;
        image.sourceUrl = [url getUrlWithoutScheme];
        image.dateRetrieved = [NSDate date];
        image.dateLastAccessed = [NSDate date];
        image.width = @(width.integerValue);
        image.height = @(height.integerValue);
        image.mimeType = [image.extension getImageMimeTypeForExtension];
    }
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC");
}
*/

@end
