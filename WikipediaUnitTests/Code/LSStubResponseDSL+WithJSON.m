//
//  LSStubResponseDSL+WithJSON.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "LSStubResponseDSL+WithJSON.h"

@implementation LSStubResponseDSL (WithJSON)

- (WithJSONMethod)withJSON {
    return ^LSStubResponseDSL *(id json) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
        NSAssert(jsonData, @"Failed to serialize provided JSON fixture: %@", json);
        return self.withHeader(@"Content-Type", @"application/json")
            .withBody(jsonData);
    };
}

@end
