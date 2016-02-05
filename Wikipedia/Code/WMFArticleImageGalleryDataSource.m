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
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleImageGalleryDataSource ()

@property (nonatomic, strong, readwrite) MWKArticle* article;

@end

@implementation WMFArticleImageGalleryDataSource
@dynamic emptyView;

- (instancetype)initWithArticle:(MWKArticle*)article {
    
    NSArray* images = [article.images.uniqueLargestVariants bk_select:^BOOL (MWKImage* image) {
        // Keep image if it's the article image even if we can't determine its size - we
        // always want to show article image as first "lead" image by gallery.
        if ([article.image isEqualToImage:image]) {
            return YES;
        }
        
        if (!image.width || !image.height) {
            // HAX: if this image MWKImage record doesn't have a width and height value (because
            // it wasn't determined by parsing it from the article HTML's image url) see if the
            // cache can tell us the size.
            UIImage* img = [[WMFImageController wmf_appImageCache] imageFromDiskCacheForKey:image.sourceURLString];
            image.width  = @(img.size.width);
            image.height = @(img.size.height);
            // Should we update the image's MWKImage record here so next time it *will* have the size?
        }
        
        return [image isLargeEnoughForGalleryInclusion];
    }];
    
    self = [super wmf_initWithItemsAndReverseIfNeeded:images];
    if (self) {
        self.article   = article;
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

- (nullable NSURL*)imageURLAtIndexPath:(NSIndexPath*)indexPath {
    return [[[self imageAtIndexPath:indexPath] largestVariant] sourceURL];
}

@end

NS_ASSUME_NONNULL_END
