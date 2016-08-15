//
//  NSBundle+TestAssets.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (TestAssets)

- (NSString *)wmf_stringFromContentsOfFile:(NSString *)filename ofType:(NSString *)type;

- (NSData *)wmf_dataFromContentsOfFile:(NSString *)filename ofType:(NSString *)type;

- (id)wmf_jsonFromContentsOfFile:(NSString *)filename;

@end
