//
//  SaveThumbnailFetcher.m
//  Wikipedia
//
//  Created by Brion on 12/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "SaveThumbnailFetcher.h"

@implementation SaveThumbnailFetcher

-(instancetype)initAndFetchThumbnailFromURL: (NSString *)url
                                 forArticle: (MWKArticle *)article
                                withManager: (AFHTTPRequestOperationManager *)manager;
{
    if (![url hasPrefix:@"http"]) {
        url = [@"https:" stringByAppendingString:url];
    }
    self = [super initAndFetchThumbnailFromURL:url withManager:manager thenNotifyDelegate:self];
    if (self) {
        _article = article;
    }
    return self;
}

-(void)fetchFinished:(id)sender fetchedData:(id)fetchedData status:(FetchFinalStatus)status error:(NSError *)error
{
    // WARNING: This currently always fails, the article queue manager needs to be fixed
    // to accept raw data, this is coming in a future merge.
    if (status == FETCH_FINAL_STATUS_SUCCEEDED) {
        MWKImage *image = [self.article importImageURL:self.url sectionId:MWK_SECTION_THUMBNAIL];
        [self.article importImageData:fetchedData image:image mimeType:@"image"];
    }
}

@end
