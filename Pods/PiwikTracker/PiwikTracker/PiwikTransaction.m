//
//  PiwikTransaction.m
//  PiwikTracker
//
//  Created by Mattias Levin on 19/01/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import "PiwikTransaction.h"
#import "PiwikTransactionBuilder.h"


@implementation PiwikTransaction


+ (instancetype)transactionWithBuilder:(TransactionBuilderBlock)block {
  NSParameterAssert(block);
  
  PiwikTransactionBuilder *builder = [[PiwikTransactionBuilder alloc] init];
  block(builder);
  
  return [builder build];
}


- (id)initWithBuilder:(PiwikTransactionBuilder*)builder {
  
  self = [super init];
  if (self) {
    _identifier = builder.identifier;
    _grandTotal = builder.grandTotal;
    _subTotal = builder.subTotal;
    _tax = builder.tax;
    _shippingCost = builder.shippingCost;
    _discount = builder.discount;
    _items = builder.items;
  }
  return self;
}


@end
