//  Created by Monte Hurd on 12/23/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "Article.h"

@interface Article (Convenience)

- (NSArray *)getSectionImagesUsingContext:(NSManagedObjectContext *)context;
- (NSArray *)getSectionsUsingContext:(NSManagedObjectContext *)context;

// Returns thumb for article. If not found returns first section image for article
// larger than 99 x 99 px.
- (UIImage *)getThumbnailUsingContext:(NSManagedObjectContext *)context;

- (void)ifNoThumbnailUseFirstSectionImageAsThumbnailUsingContext:(NSManagedObjectContext *)context;

- (NSURL *)desktopURL;

//@property (readonly) MWPageTitle* titleObj;

@property (readonly) BOOL editableBool;

@end
