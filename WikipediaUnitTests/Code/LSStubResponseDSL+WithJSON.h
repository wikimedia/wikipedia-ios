//
//  LSStubResponseDSL+WithJSON.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Nocilla/Nocilla.h>

typedef LSStubResponseDSL*(^ WithJSONMethod)(id json);

@interface LSStubResponseDSL (WithJSON)

@property (nonatomic, strong, readonly) WithJSONMethod withJSON;

@end
