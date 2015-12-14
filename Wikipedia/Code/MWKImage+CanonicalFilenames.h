//
//  MWKImage+CanonicalFilenames.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImage.h"

@interface MWKImage (CanonicalFilenames)

+ (NSArray*)mapFilenamesFromImages:(NSArray<MWKImage*>*)images;

@end
