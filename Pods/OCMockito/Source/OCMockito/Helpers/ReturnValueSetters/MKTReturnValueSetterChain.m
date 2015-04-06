//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTReturnValueSetterChain.h"

#import "MKTObjectReturnSetter.h"
#import "MKTClassReturnSetter.h"
#import "MKTCharReturnSetter.h"
#import "MKTBoolReturnSetter.h"
#import "MKTLongLongReturnSetter.h"
#import "MKTIntReturnSetter.h"
#import "MKTShortReturnSetter.h"
#import "MKTLongReturnSetter.h"
#import "MKTUnsignedCharReturnSetter.h"
#import "MKTUnsignedIntReturnSetter.h"
#import "MKTUnsignedShortReturnSetter.h"
#import "MKTUnsignedLongReturnSetter.h"
#import "MKTUnsignedLongLongReturnSetter.h"
#import "MKTFloatReturnSetter.h"
#import "MKTDoubleReturnSetter.h"
#import "MKTStructReturnSetter.h"


MKTReturnValueSetter *MKTReturnValueSetterChain(void)
{
    static MKTReturnValueSetter *chain = nil;
    if (!chain)
    {
        MKTReturnValueSetter *structSetter = [[MKTStructReturnSetter alloc] initWithSuccessor:nil];
        MKTReturnValueSetter *doubleSetter = [[MKTDoubleReturnSetter alloc] initWithSuccessor:structSetter];
        MKTReturnValueSetter *floatSetter = [[MKTFloatReturnSetter alloc] initWithSuccessor:doubleSetter];
        MKTReturnValueSetter *uLongLongSetter = [[MKTUnsignedLongLongReturnSetter alloc] initWithSuccessor:floatSetter];
        MKTReturnValueSetter *uLongSetter = [[MKTUnsignedLongReturnSetter alloc] initWithSuccessor:uLongLongSetter];
        MKTReturnValueSetter *uShortSetter = [[MKTUnsignedShortReturnSetter alloc] initWithSuccessor:uLongSetter];
        MKTReturnValueSetter *uIntSetter = [[MKTUnsignedIntReturnSetter alloc] initWithSuccessor:uShortSetter];
        MKTReturnValueSetter *uCharSetter = [[MKTUnsignedCharReturnSetter alloc] initWithSuccessor:uIntSetter];
        MKTReturnValueSetter *longLongSetter = [[MKTLongLongReturnSetter alloc] initWithSuccessor:uCharSetter];
        MKTReturnValueSetter *longSetter = [[MKTLongReturnSetter alloc] initWithSuccessor:longLongSetter];
        MKTReturnValueSetter *shortSetter = [[MKTShortReturnSetter alloc] initWithSuccessor:longSetter];
        MKTReturnValueSetter *intSetter = [[MKTIntReturnSetter alloc] initWithSuccessor:shortSetter];
        MKTReturnValueSetter *boolSetter = [[MKTBoolReturnSetter alloc] initWithSuccessor:intSetter];
        MKTReturnValueSetter *charSetter = [[MKTCharReturnSetter alloc] initWithSuccessor:boolSetter];
        MKTReturnValueSetter *classSetter = [[MKTClassReturnSetter alloc] initWithSuccessor:charSetter];
        MKTReturnValueSetter *objectSetter = [[MKTObjectReturnSetter alloc] initWithSuccessor:classSetter];
        chain = objectSetter;
    }
    return chain;
}
