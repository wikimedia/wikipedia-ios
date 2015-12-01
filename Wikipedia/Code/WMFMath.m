#import "WMFMath.h"
#import <math.h>

double WMFRoundedPercentage(double (* rounder)(double), double x, unsigned int precision) {
    double const shifter = 1.0 * precision;
    return (*rounder)(x * shifter) / shifter;
}

double WMFFlooredPercentage(double x) {
    return WMFRoundedPercentage(floor, x, 100);
}

