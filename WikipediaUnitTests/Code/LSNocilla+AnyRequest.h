#import <Nocilla/Nocilla.h>

static inline LSStubRequestDSL *stubAnyRequest() {
    NSError *regexError;
    NSRegularExpression *anyRequestRegex =
        [NSRegularExpression regularExpressionWithPattern:@".*"
                                                  options:0
                                                    error:&regexError];
    NSCParameterAssert(!regexError);
    return stubRequest(@"GET", anyRequestRegex);
}
