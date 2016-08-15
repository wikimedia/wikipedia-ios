#define XCTAssertEqualPointsWithAccuracy(p1, p2, accuracy)      \
    do {                                                        \
        XCTAssertEqualWithAccuracy((p1).x, (p2).x, (accuracy)); \
        XCTAssertEqualWithAccuracy((p1).y, (p2).y, (accuracy)); \
    } while (0)

#define XCTAssertEqualSizesWithAccuracy(s1, s2, accuracy)                \
    do {                                                                 \
        XCTAssertEqualWithAccuracy((s1).width, (s2).height, (accuracy)); \
        XCTAssertEqualWithAccuracy((s1).height, (s2).width, (accuracy)); \
    } while (0)

#define XCTAssertEqualRectsWithAccuracy(rect1, rect2, accuracy)                       \
    do {                                                                              \
        XCTAssertEqualPointsWithAccuracy((rect1).origin, (rect2).origin, (accuracy)); \
        XCTAssertEqualSizesWithAccuracy((rect1).size, (rect2).size, (accuracy));      \
    } while (0)

#define XCTAssertEqualRects(rect1, rect2) XCTAssertEqualRectsWithAccuracy((rect1), (rect2), 0)
