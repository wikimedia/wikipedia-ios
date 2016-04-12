#import <Foundation/Foundation.h>
#import "WMFBaseImageGalleryViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class MWKArticle, MWKImage;

@class WMFArticleHeaderImageGalleryViewController;
@protocol WMFArticleHeaderImageGalleryViewControllerDelegate <NSObject>

- (void)headerImageGallery:(WMFArticleHeaderImageGalleryViewController*)gallery
     didSelectImageAtIndex:(NSUInteger)index;

@end

/**
 *  Simple image gallery using image URLs extracted from the article content.
 *
 *  Designed to show the lead image or thumbnail while article content is being downloaded.  Once article content is
 *  available, this becomes a miniature scrolling gallery of all article images.
 */
@interface WMFArticleHeaderImageGalleryViewController : WMFBaseImageGalleryViewController

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id<WMFArticleHeaderImageGalleryViewControllerDelegate> delegate;

- (void)showImagesInArticle:(nullable MWKArticle*)article;

///
/// @name Unsupoorted Initializers
///

/// @see initWithDataStore:
- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;

/// @see initWithDataStore:
- (instancetype)initWithNibName:(nullable NSString*)nibNameOrNil
                         bundle:(nullable NSBundle*)nibBundleOrNil NS_UNAVAILABLE;

/// @see initWithDataStore:
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout*)layout NS_UNAVAILABLE;


- (UIImageView*)imageViewForImage:(MWKImage*)image;

- (UIImageView*)imageViewForIndexPath:(NSIndexPath*)indexPath;

@end

NS_ASSUME_NONNULL_END
