//
//  PiwikTransactionBuilder.m
//  PiwikTracker
//
//  Created by Mattias Levin on 19/01/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import "PiwikTransactionBuilder.h"
#import "PiwikTransaction.h"
#import "PiwikTransactionItem.h"


@implementation PiwikTransactionBuilder


- (instancetype)init {
  self = [super init];
  if (self) {
    _items = [[NSMutableArray alloc] init];
  }
  return self;
}


- (void)addItemWithSku:(NSString*)sku {
  PiwikTransactionItem *item = [PiwikTransactionItem itemWithSKU:sku];
  [self addTransactionItem:item];
}


- (void)addItemWithSku:(NSString*)sku
                  name:(NSString*)name
              category:(NSString*)category
                 price:(float)price
              quantity:(NSUInteger)quantity {
  
  PiwikTransactionItem *item = [PiwikTransactionItem itemWithSku:sku name:name category:category price:price quantity:quantity];
  [self addTransactionItem:item];
}


- (void)addTransactionItem:(PiwikTransactionItem*)item {
  [self.items addObject:item];
}


- (PiwikTransaction*)build {
  
  // Verify that mandatory parameters have been set
  __block BOOL isTransactionValid = self.identifier.length > 0 && self.grandTotal;
  
  [self.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    PiwikTransactionItem *item = (PiwikTransactionItem*)obj;
    if (!item.isValid) {
      isTransactionValid = NO;
      *stop = YES;
    }
  }];
  
  if (isTransactionValid) {
    return [[PiwikTransaction alloc] initWithBuilder:self];
  } else {
    NSLog(@"Failed to build transaction, missing mandatory parameters");
    return nil;
  }
  
}


@end
