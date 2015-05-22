//  Created by Monte Hurd on 4/22/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface NSURL (WMFRest)

- (BOOL)wmf_conformsToScheme:(NSString*)scheme andHasHost:(NSString*)host;
- (BOOL)wmf_conformsToAnyOfSchemes:(NSArray*)schemes andHasHost:(NSString*)host;
- (NSString*)wmf_getValue;

@end
