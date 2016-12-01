@import Quick;
@import Nimble;
#import "NSDate+WMFPOTDTitle.h"

static inline NSString *expectedPOTDTitleStringForYearMonthDay(NSInteger year, NSInteger month, NSInteger day) {
    return [NSString stringWithFormat:@"%@/%ld-%02ld-%02ld_(en)", WMFPOTDTitlePrefix, (long)year, (long)month, (long)day];
}

QuickSpecBegin(NSDate_WMFPOTDTitleTests)

    describe(@"potd date formatting", ^{
        it(@"should always have two digits for the month & day", ^{
            NSDateComponents *testDateComponents = [[NSDateComponents alloc] init];
            testDateComponents.calendar = [NSCalendar currentCalendar];
            testDateComponents.day = 1;
            testDateComponents.month = 1;
            testDateComponents.year = 2015;
            expect([testDateComponents.date wmf_picOfTheDayPageTitle])
                .to(equal(expectedPOTDTitleStringForYearMonthDay(testDateComponents.year,
                                                                 testDateComponents.month,
                                                                 testDateComponents.day)));

            testDateComponents.day = 10;
            testDateComponents.month = 10;
            testDateComponents.year = 2015;
            expect([testDateComponents.date wmf_picOfTheDayPageTitle])
                .to(equal(expectedPOTDTitleStringForYearMonthDay(testDateComponents.year,
                                                                 testDateComponents.month,
                                                                 testDateComponents.day)));
        });
    });

QuickSpecEnd
