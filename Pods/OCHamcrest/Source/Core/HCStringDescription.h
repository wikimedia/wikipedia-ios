//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <OCHamcrest/HCBaseDescription.h>

@protocol HCSelfDescribing;


/*!
 * @brief An @ref HCDescription that is stored as a string.
 */
@interface HCStringDescription : HCBaseDescription
{
    NSMutableString *accumulator;
}

/*!
 * @brief Returns the description of an HCSelfDescribing object as a string.
 * @param selfDescribing The object to be described.
 * @return The description of the object.
 */
+ (NSString *)stringFrom:(id<HCSelfDescribing>)selfDescribing;

/*!
 * @brief Creates and returns an empty description.
 */
+ (instancetype)stringDescription;

/*!
 * @brief Initializes a newly allocated HCStringDescription that is initially empty.
 */
- (instancetype)init;

@end
