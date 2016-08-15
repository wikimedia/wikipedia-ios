#ifndef Wikipedia_WMFHashing_h
#define Wikipedia_WMFHashing_h

static NSUInteger const NSUINT_BIT = sizeof(NSUInteger) * CHAR_BIT;
static NSUInteger const NSUINT_BIT_2 = NSUINT_BIT / 2;

// taken from MA's blog:
// https://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html
static inline NSUInteger flipBitsWithAdditionalRotation(NSUInteger x, NSUInteger rotation) {
    // take the amount and adjust it by half the size of x, so a rotation of 0 results in flipping the bits
    rotation += NSUINT_BIT_2;
    return (x << rotation) | (x >> (NSUINT_BIT - rotation));
}

#endif
