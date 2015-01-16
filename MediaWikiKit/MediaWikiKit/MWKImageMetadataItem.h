//
//  MWKImageMetadataItem.h
//  MediaWikiKit
//
//  Created by Brion on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataObject.h"

@interface MWKImageMetadataItem : MWKDataObject

@property (readonly) NSString *value;
@property (readonly) NSString *source;
@property (readonly) BOOL hidden;

-(instancetype)initWithDict:(NSDictionary *)dict;

@end
