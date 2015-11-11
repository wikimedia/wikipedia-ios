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

@end
