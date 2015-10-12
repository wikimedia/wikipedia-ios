//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <Foundation/Foundation.h>
#import <OCHamcrest/HCDescription.h>


/*!
 * @brief Base class for all @ref HCDescription implementations.
 */
@interface HCBaseDescription : NSObject <HCDescription>
@end


/*!
 * @brief Methods that must be provided by subclasses of HCBaseDescription.
 */
@interface HCBaseDescription (SubclassResponsibility)

/*!
 * @brief Appends the given string to the description.
 */
- (void)append:(NSString *)str;

@end
