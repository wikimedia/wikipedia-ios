/**
 * Round @c x to @c precision using the @c rounder function.
 * @param rounder   Function which rounds a given number.
 * @param x         The number to round.
 * @param precision The number of significant digits to round to after the decimal point.
 */
extern double RoundWithPrecision(double (* rounder)(double), double x, unsigned int precision);

/// Round @c x to 2 significant digits after the decimal point.
extern double FlooredPercentage(double x) __attribute__((const)) __attribute__((pure));