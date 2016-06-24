//
//  MWKArticle+HTMLImageImport.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticle.h"

@class TFHppleElement;

@interface MWKArticle (HTMLImageImport)

/**
 *  Parse and save all <code><img></code> tags into @c MWKImage objects from the receiver's sections' HTML
 */
- (void)importAndSaveImagesFromSectionHTML;

/**
 *  Internal API for creating, importing, and saving the @c src images in an image node.
 *
 *  @c importAndSaveImagesFromSectionHTML calls this internally on all image elements from all section HTML. Therefore,
 *  you shouldn't need to call this directly.
 *
 *  @param imageNode The image node to extract image metadata from.
 *  @param sectionID The section to add the image to.
 */
- (void)importAndSaveImagesFromElement:(TFHppleElement*)imageNode intoSection:(int)sectionID;

@end
