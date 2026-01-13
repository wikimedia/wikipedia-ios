#import <WMF/WMFMath.h>
#import <math.h>

double WMFRoundedPercentage(double (*rounder)(double), double x, unsigned int precision) {
    double const shifter = 1.0 * precision;
    return (*rounder)(x * shifter) / shifter;
}

NSInteger WMFRadiansToClock(double radians) {
    double unitRadians = fmod(radians, 2 * M_PI);
    double positiveRadians = unitRadians >= 0 ? unitRadians : unitRadians + 2 * M_PI;
    NSInteger clockDirection = lroundf(positiveRadians / (M_PI / 6));
    if (clockDirection == 0) {
        clockDirection = 12;
    }
    return clockDirection;
}
