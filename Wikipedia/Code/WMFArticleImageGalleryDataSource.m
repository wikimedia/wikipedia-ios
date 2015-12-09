//
//  WMFArticleImageDataSource.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/10/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleImageGalleryDataSource.h"
#import "MWKArticle.h"
#import "MWKImageList.h"
#import "MWKImage.h"
#import "UIImageView+WMFImageFetching.h"
#import "UIImageView+WMFPlaceholder.h"
#import "SSArrayDataSource+WMFReverseIfRTL.h"

@implementation WMFArticleImageGalleryDataSource
@dynamic emptyView;

- (instancetype)initWithArticle:(MWKArticle*)article {
    self = [super wmf_initWithItemsAndReverseIfNeeded:article.images.uniqueLargestVariants];
    if (self) {
        self.emptyView = [[UIImageView alloc] init];
        [self applyLeadImageIfEmpty];
    }
    return self;
}

- (void)applyLeadImageIfEmpty {
    if ([self numberOfItems] == 0) {
        UIImageView* emptyImageView = (UIImageView*)self.emptyView;
        if ([emptyImageView isKindOfClass:[UIImageView class]]) {
            [emptyImageView wmf_configureWithDefaultPlaceholder];
            [emptyImageView wmf_setImageWithMetadata:self.article.image ? : self.article.thumbnail detectFaces:YES];
        } else {
            DDLogError(@"Unexpected empty view for image gallery data source: %@", self.emptyView);
        }
    }
}

- (MWKImage*)imageAtIndexPath:(NSIndexPath*)indexPath {
    return [self itemAtIndexPath:indexPath];
}

- (NSURL*)imageURLAtIndexPath:(NSIndexPath*)indexPath {
    return [[[self imageAtIndexPath:indexPath] largestVariant] sourceURL];
}

@end
