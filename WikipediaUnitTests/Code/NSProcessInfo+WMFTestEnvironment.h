//
//  NSProcessInfo+WMFTestEnvironment.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/27/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSProcessInfo (WMFTestEnvironment)

- (BOOL)wmf_isTravis;

@end
