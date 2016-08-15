//
//  MWKImage+CanonicalFilenames.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImage.h"

@interface MWKImage (CanonicalFilenames)

/**
 * Map an array of "File:..." titles from an array of images.
 *
 * @warning The returned array will contain @c NSNull instances for each image which could not parse its canonical
 *          filename. This is intentional.
 *
 * Uses the images' @c canonicalFilename property, which is parsed from its @c sourceURL.
 *
 * @return An array of @c NSString objects for successfully constructed "File:..." titles or <code>[NSNull null]</code>
 *         for images whose URLs could not be parsed successfully.
 */
+ (NSArray *)mapFilenamesFromImages:(NSArray<MWKImage *> *)images;

@end
