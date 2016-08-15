//
//  NSObject+WMFReflection.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <objc/runtime.h>

typedef void (^WMFObjCPropertyEnumerator)(objc_property_t, BOOL *stop);

/**
 *  Reflection utilities inspired by Mantle's runtime methods.
 */
@interface NSObject (WMFReflection)

+ (void)wmf_enumeratePropertiesUntilSuperclass:(Class)superClass usingBlock:(WMFObjCPropertyEnumerator)block;

@end
