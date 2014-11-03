//
//  MWKArticleStoreTestCase.h
//  MediaWikiKit
//
//  Created by Brion on 10/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKTestCase.h"

@interface MWKArticleStoreTestCase : MWKTestCase

@property MWKSite *site;
@property MWKTitle *title;
@property NSDictionary *json0;
@property NSDictionary *json1;

@property NSString *basePath;
@property MWKDataStore *dataStore;
@property MWKArticleStore *articleStore;

@end
