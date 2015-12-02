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
#import "NSArray+WMFLayoutDirectionUtilities.h"

@implementation WMFArticleImageGalleryDataSource
@dynamic emptyView;

- (instancetype)initWithTarget:(id)target keyPath:(NSString*)keyPath {
    self = [super initWithTarget:target keyPath:keyPath];
    if (self) {
        self.emptyView = [[UIImageView alloc] init];
    }
    return self;
}

- (void)setArticle:(MWKArticle*)article {
    if (WMF_EQUAL(_article, isEqualToArticle:, article)) {
        return;
    }
    _article = article;
    NSArray* images = article.images.uniqueLargestVariants;
    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]) {
        images = [images wmf_reverseArrayIfApplicationIsRTL];
    }
    [self updateItems:images];
    [self applyLeadImageIfEmpty];
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
