//
//  MWKSection+HTMLImageExtraction.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSection.h"

@class TFHppleElement;

@interface MWKSection (HTMLImageParsing)

- (NSArray<TFHppleElement*>*)parseImageElements;

@end

@interface NSString (WMFHTMLImageParsing)

- (instancetype)wmf_stringBySelectingHTMLImageTags;

@end
