//
//  NSProcessInfo+WMFTestEnvironment.m
//  Wikipedia
//
//  Created by Brian Gerstle on 1/27/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "NSProcessInfo+WMFTestEnvironment.h"

@implementation NSProcessInfo (WMFTestEnvironment)

- (BOOL)wmf_isTravis {
  return self.environment[@"TRAVIS"].length > 0;
}

@end
