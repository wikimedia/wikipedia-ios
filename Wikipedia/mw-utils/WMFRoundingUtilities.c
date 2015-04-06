#import "WMFRoundingUtilities.h"
#import <math.h>

double RoundedPercentage(double(*rounder)(double), double x, unsigned int precision) {
    double const shifter = 1.0 * precision;
    return (*rounder)(x * shifter) / shifter;
}

double FlooredPercentage(double x) {
    return RoundedPercentage(floor, x, 100);
}
