@import OMGHTTPURLRQ;
@import XCTest;


@interface Tests: XCTestCase @end @implementation Tests

- (void)test1 {
    id input = @{ 
        @"propStr1": @"str1",
        @"propStr2": @"str2",
        @"propArr1": @[@"arrStr1[]", @"arrStr2"]
    };
    id output = OMGFormURLEncode(input);
    id expect = @"propArr1[]=arrStr1%5B%5D&propArr1[]=arrStr2&propStr1=str1&propStr2=str2";
    XCTAssertEqualObjects(output, expect);
}

- (void)test2 {
    id input = @{@"key": @" !\"#$%&'()*+,/[]"};
    id output = OMGFormURLEncode(input);
    id expect = @"key=%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F%5B%5D";
    XCTAssertEqualObjects(output, expect);
}

- (void)test3 {
    id input = @{@"key": @{@"key": @"value"}};
    id output = OMGFormURLEncode(input);
    id expect = @"key[key]=value";
    XCTAssertEqualObjects(output, expect);
}

- (void)test4 {
    id input = @{@"key": @{@"key": @{@"+": @"value value", @"-": @";"}}};
    id output = OMGFormURLEncode(input);
    id expect = @"key[key][%2B]=value%20value&key[key][-]=%3B";
    XCTAssertEqualObjects(output, expect);
}

- (void)test5 {
    NSURLRequest *rq = [OMGHTTPURLRQ GET:@"http://example.com":@{@"key":@" !\"#$%&'()*+,/"} error:nil];
    XCTAssertEqualObjects(rq.URL.query, @"key=%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F");
}

- (void)test6 {
    id params = @{@"key": @"%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F"};
    NSURLRequest *rq = [OMGHTTPURLRQ GET:@"http://example.com":params error:nil];
    XCTAssertEqualObjects(rq.URL.query, @"key=%2520%2521%2522%2523%2524%2525%2526%2527%2528%2529%252A%252B%252C%252F");
}

- (void)test7 {
    id params = @{@"key":@"value"};
    id rq = [OMGHTTPURLRQ POST:@"http://example.com" JSON:params error:nil];

    NSString *body = [[NSString alloc] initWithData:[rq HTTPBody] encoding:NSUTF8StringEncoding];

    XCTAssertEqualObjects(@"{\"key\":\"value\"}", body, @"Parameters were not encoded correctly");
}

- (void)test8 {
    id params = @[@{@"key":@"value"}];
    id rq = [OMGHTTPURLRQ POST:@"http://example.com" JSON:params error:nil];

    NSString *body = [[NSString alloc] initWithData:[rq HTTPBody] encoding:NSUTF8StringEncoding];

    XCTAssertEqualObjects(@"[{\"key\":\"value\"}]", body, @"Parameters were not encoded correctly");
}

@end
