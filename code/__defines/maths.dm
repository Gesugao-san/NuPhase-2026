// Macro functions.
#define RAND_F(LOW, HIGH) (rand() * (HIGH - LOW) + LOW)
#define CEILING(x) (-round(-(x)))
#define MULT_BY_RANDOM_COEF(VAR,LO,HI) VAR =  round((VAR * rand(LO * 100, HI * 100))/100, 0.1)
#define PERCENT(value, max, places) round((value) / (max) * 100, !(places) || 10 ** -(places))

// Float-aware floor and ceiling since round() will round upwards when given a second arg.
#define NONUNIT_FLOOR(x, y)    (floor((x) / (y)) * (y))
#define NONUNIT_CEILING(x, y) (ceil((x) / (y)) * (y))

// Special two-step rounding for reagents, to avoid floating point errors.
#define CHEMS_QUANTIZE(x) NONUNIT_FLOOR(round(x, MINIMUM_CHEMICAL_VOLUME * 0.1), MINIMUM_CHEMICAL_VOLUME)

#define ROUND(x) (((x) >= 0) ? round((x)) : -round(-(x)))
#define FLOOR(x) (round(x))
#define EULER 2.7182818285

#define MODULUS_FLOAT(X, Y) ( (X) - (Y) * round((X) / (Y)) )

// Will filter out extra rotations and negative rotations
// E.g: 540 becomes 180. -180 becomes 180.
#define SIMPLIFY_DEGREES(degrees) (MODULUS_FLOAT((degrees), 360))