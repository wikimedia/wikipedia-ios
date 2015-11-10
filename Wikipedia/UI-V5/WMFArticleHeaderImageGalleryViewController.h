#import <Foundation/Foundation.h>
#import "WMFPageCollectionViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class MWKArticle;

@class WMFArticleHeaderImageGalleryViewController;
@protocol WMFArticleHeaderImageGalleryViewControllerDelegate <NSObject>

- (void)headerImageGallery:(WMFArticleHeaderImageGalleryViewController*)gallery didSelectImageAtIndex:(NSUInteger)index;

@end

/**
 *  Simple image gallery using image URLs extracted from the article content.
 *
 *  Designed to show the lead image or thumbnail while article content is being downloaded.  Once article content is
 *  available, this becomes a miniature scrolling gallery of all article images.
 */
@interface WMFArticleHeaderImageGalleryViewController : WMFPageCollectionViewController

@property (nonatomic, weak) id<WMFArticleHeaderImageGalleryViewControllerDelegate> delegate;

/// Images to display in the gallery.
@property (nonatomic, copy, null_resettable) NSArray* images;

/**
 * Reset the contents of the receiver's `imageURLs` array to contain the images from the specified article.
 *
 * If the article is not cached, it will only populate the gallery with either the lead or thumbnail image URL.
 *
 * @param article The article whose images should populate the gallery.
 */
- (void)setImagesFromArticle:(MWKArticle*)article;

@end

NS_ASSUME_NONNULL_END
