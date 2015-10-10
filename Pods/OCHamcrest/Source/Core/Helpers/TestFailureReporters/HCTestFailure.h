//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <Foundation/Foundation.h>


/*!
 @brief Test failure location and reason.
 */
@interface HCTestFailure : NSObject

/*!
 * @brief Test case used to run test method.
 * @discussion Can be <code>nil</code>.
 *
 * For unmet OCHamcrest assertions, if the assertion was @ref assertThat or @ref assertWithTimeout,
 * <em>testCase</em> will be the test case instance.
 */
@property (nonatomic, strong, readonly) id testCase;

/*! @brief File name to report. */
@property (nonatomic, copy, readonly) NSString *fileName;

/*! @brief Line number to report. */
@property (nonatomic, assign, readonly) NSUInteger lineNumber;

/*! @brief Failure reason to report. */
@property (nonatomic, strong, readonly) NSString *reason;

/*!
 * @brief Initializes a newly allocated instance of a test failure.
 */
- (instancetype)initWithTestCase:(id)testCase
                        fileName:(NSString *)fileName
                      lineNumber:(NSUInteger)lineNumber
                          reason:(NSString *)reason;

@end
