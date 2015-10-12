//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import "HCRequireNonNilObject.h"


void HCRequireNonNilObject(id obj)
{
    if (obj == nil)
    {
        @throw [NSException exceptionWithName:@"NilObject"
                                       reason:@"Must be non-nil object"
                                     userInfo:nil];
    }
}
