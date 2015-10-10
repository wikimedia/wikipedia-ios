
#import <SSDataSources/SSDataSources.h>

@class MWKTitle;
@class MWKSavedPageList;
@class MWKImage;

/**
 *  Base class for cells which represent a title and have save button.
 *
 *  Will also be given the "card" style by applying a white background to its
 *  @c contentView as well as a small shadow.
 */
@interface WMFSaveableTitleCollectionViewCell : SSBaseCollectionCell

///
/// @name Populating the View With Data
///

/**
 *  Title associated with the receiver.
 *
 *  Setting this property updates both the @c titleLabel and @c saveButton states.
 */
@property (copy, nonatomic) MWKTitle* title;

/**
 *  The list to observe for changes to the saved state of the receiver's @c title.
 *
 *  @param savedPageList A saved page list which is mutated on the main thread.
 */
- (void)setSavedPageList:(MWKSavedPageList*)savedPageList;

/**
 *  Set an image for the receiver's image view.
 *
 *  Setting this property will cancel any previous requests, apply a placeholder, and/or fetch the image depending
 *  on where it's currently stored.
 *
 *  @param imageURL The URL to retrieve the image from.
 */
- (void)setImageURL:(NSURL*)imageURL;

/**
 *  Set an image for the receiver's image view.
 *
 *  Setting this property will cancel any previous requests, apply a placeholder, and/or fetch the image depending
 *  on where it's currently stored.
 *
 *  @note This method is preferred to @c setImageURL: since it allows the app to read & write face detection data that's
 *        stored on disk.
 *
 *  @param image The image whose sourceURL will be used to retrieve an image.
 */
- (void)setImage:(MWKImage*)image;

@end
