//
//  MWKImage+CanonicalFilenames.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImage+CanonicalFilenames.h"

@implementation MWKImage (CanonicalFilenames)

+ (NSArray *)mapFilenamesFromImages:(NSArray<MWKImage *> *)images {
  return [images wmf_mapAndRejectNil:^id(MWKImage *image) {
    NSString *canonicalFilename = image.canonicalFilename;
    if (canonicalFilename.length) {
      return [@"File:" stringByAppendingString:canonicalFilename];
    } else {
      DDLogWarn(@"Unable to form canonical filename from image: %@", image.sourceURLString);
      return nil;
    }
  }];
}

@end
