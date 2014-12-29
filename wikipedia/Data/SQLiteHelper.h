//
//  SQLiteHelper.h
//  Wikipedia
//
//  Created by Brion on 4/23/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQLiteHelper : NSObject

- (id)initWithPath:(NSString *)path;
- (NSArray *)query:(NSString *)query params:(NSArray *)params;

@end
