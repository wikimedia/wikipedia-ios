//
//  WMFModalArticleImageGalleryDataSource.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFModalArticleImageGalleryDataSource.h"
#import "WMFImageInfoController.h"
#import "MWKArticle.h"

@interface WMFModalArticleImageGalleryDataSource ()
<WMFImageInfoControllerDelegate>

@property (nonatomic, strong) WMFImageInfoController* infoController;

@end

@implementation WMFModalArticleImageGalleryDataSource
@synthesize delegate;

- (MWKImageInfo*)imageInfoAtIndexPath:(NSIndexPath*)indexPath {
    return [self.infoController infoForImage:[self imageAtIndexPath:indexPath]];
}

- (void)setArticle:(MWKArticle*)article {
    if (self.article == article) {
        return;
    }
    [super setArticle:article];
    if (!article) {
        self.infoController = nil;
        return;
    }
    self.infoController          = [[WMFImageInfoController alloc] initWithDataStore:self.article.dataStore batchSize:50];
    self.infoController.delegate = self;
    [self.infoController setUniqueArticleImages:[self allItems]
                                       forTitle:article.title];
}

- (void)imageInfoController:(WMFImageInfoController*)controller didFetchBatch:(NSRange)range {
    NSIndexSet* fetchedIndexes = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.delegate modalGalleryDataSource:self updatedItemsAtIndexes:fetchedIndexes];
}

- (void)imageInfoController:(WMFImageInfoController*)controller
         failedToFetchBatch:(NSRange)range
                      error:(NSError*)error {
    [self.delegate modalGalleryDataSource:self didFailWithError:error];
}

- (void)prefetchDataNearIndexPath:(NSIndexPath*)indexPath {
    [self.infoController fetchBatchContainingIndex:indexPath.item];
}

@end
