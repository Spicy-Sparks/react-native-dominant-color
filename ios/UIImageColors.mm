#import "UIImageColors.h"
#import <math.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Helpers (internal)

@interface UIImageColorsCounter : NSObject
@property (nonatomic) double color;
@property (nonatomic) NSInteger count;
- (instancetype)initWithColor:(double)color count:(NSInteger)count;
@end

@implementation UIImageColorsCounter
- (instancetype)initWithColor:(double)color count:(NSInteger)count {
    if (self = [super init]) {
        _color = color;
        _count = count;
    }
    return self;
}
@end

static inline double UIC_R(double packed) {
    return fmod(floor(packed / 1000000.0), 1000000.0);
}

static inline double UIC_G(double packed) {
    return fmod(floor(packed / 1000.0), 1000.0);
}

static inline double UIC_B(double packed) {
    return fmod(packed, 1000.0);
}

static inline double UIC_PackRGB(double r, double g, double b) {
    return floor(r) * 1000000.0 + floor(g) * 1000.0 + floor(b);
}

static inline BOOL UIC_IsDark(double c) {
    return (UIC_R(c)*0.2126 + UIC_G(c)*0.7152 + UIC_B(c)*0.0722) < 127.5;
}

static inline BOOL UIC_IsBlackOrWhite(double c) {
    double r = UIC_R(c), g = UIC_G(c), b = UIC_B(c);
    return ((r > 232 && g > 232 && b > 232) || (r < 23 && g < 23 && b < 23));
}

static inline BOOL UIC_IsDistinct(double a, double b) {
    double ar = UIC_R(a), ag = UIC_G(a), ab = UIC_B(a);
    double br = UIC_R(b), bg = UIC_G(b), bb = UIC_B(b);
    return (fabs(ar - br) > 63.75 || fabs(ag - bg) > 63.75 || fabs(ab - bb) > 63.75)
        && !(fabs(ar - ag) < 7.65 && fabs(ar - ab) < 7.65
          && fabs(br - bg) < 7.65 && fabs(br - bb) < 7.65);
}

static inline double UIC_WithMinSaturation(double c, double minSat) {
    // RGB -> HSV
    double r = UIC_R(c)/255.0, g = UIC_G(c)/255.0, b = UIC_B(c)/255.0;
    double M = fmax(r, fmax(g, b));
    double m = fmin(r, fmin(g, b));
    double C = M - m;

    double V = M;
    double S = (V == 0.0) ? 0.0 : (C / V);

    if (minSat <= S) return c;

    double H;
    if (C == 0.0) {
        H = 0.0;
    } else if (r == M) {
        H = fmod((g - b) / C, 6.0);
    } else if (g == M) {
        H = 2.0 + (b - r) / C;
    } else {
        H = 4.0 + (r - g) / C;
    }
    if (H < 0.0) H += 6.0;

    // HSV' -> RGB'
    C = V * minSat;
    double X = C * (1.0 - fabs(fmod(H, 2.0) - 1.0));

    double R, G, B;
    if (H >= 0 && H <= 1)      { R = C; G = X; B = 0; }
    else if (H <= 2)           { R = X; G = C; B = 0; }
    else if (H <= 3)           { R = 0; G = C; B = X; }
    else if (H <= 4)           { R = 0; G = X; B = C; }
    else if (H <= 5)           { R = X; G = 0; B = C; }
    else /* H < 6 */           { R = C; G = 0; B = X; }

    double m2 = V - C;
    return UIC_PackRGB(floor((R + m2)*255.0), floor((G + m2)*255.0), floor((B + m2)*255.0));
}

static inline BOOL UIC_IsContrasting(double a, double b) {
    double bgLum = (0.2126*UIC_R(a) + 0.7152*UIC_G(a) + 0.0722*UIC_B(a)) + 12.75;
    double fgLum = (0.2126*UIC_R(b) + 0.7152*UIC_G(b) + 0.0722*UIC_B(b)) + 12.75;
    return (bgLum > fgLum) ? (1.6 < bgLum/fgLum) : (1.6 < fgLum/bgLum);
}

#if TARGET_OS_OSX
static inline UIColor *UIC_ColorFromPacked(double c) {
    return [NSColor colorWithCalibratedRed:(CGFloat)(UIC_R(c)/255.0)
                                     green:(CGFloat)(UIC_G(c)/255.0)
                                      blue:(CGFloat)(UIC_B(c)/255.0)
                                     alpha:1.0];
}
#else
static inline UIColor *UIC_ColorFromPacked(double c) {
    return [UIColor colorWithRed:(CGFloat)(UIC_R(c)/255.0)
                           green:(CGFloat)(UIC_G(c)/255.0)
                            blue:(CGFloat)(UIC_B(c)/255.0)
                           alpha:1.0];
}
#endif

#pragma mark - UIImageColors

@implementation UIImageColors

- (instancetype)initWithBackground:(UIColor *)background
                           primary:(UIColor *)primary
                         secondary:(UIColor *)secondary
                            detail:(UIColor *)detail {
    if (self = [super init]) {
        _background = background;
        _primary = primary;
        _secondary = secondary;
        _detail = detail;
    }
    return self;
}

@end

#pragma mark - Resizing

#if TARGET_OS_OSX
static UIImage * _Nullable UIC_ResizeImage(UIImage *image, CGSize newSize) {
    NSRect frame = NSMakeRect(0, 0, newSize.width, newSize.height);
    NSImageRep *rep = [image bestRepresentationForRect:frame context:nil hints:nil];
    if (!rep) return nil;
    NSImage *result = [[NSImage alloc] initWithSize:newSize];
    [result lockFocus];
    BOOL ok = [rep drawInRect:frame];
    [result unlockFocus];
    return ok ? result : nil;
}
#else
static UIImage * _Nullable UIC_ResizeImage(UIImage *image, CGSize newSize) {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:(CGRect){.origin = CGPointZero, .size = newSize}];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}
#endif

#pragma mark - Core extraction

static UIImageColors * _Nullable UIC_GetColors(UIImage *image, UIImageColorsQuality quality) {
    CGSize size = image.size;
    if (quality != UIImageColorsQualityHighest) {
        if (size.width < size.height) {
            CGFloat ratio = size.height / size.width;
            size = CGSizeMake((CGFloat)quality / ratio, (CGFloat)quality);
        } else {
            CGFloat ratio = size.width / size.height;
            size = CGSizeMake((CGFloat)quality, (CGFloat)quality / ratio);
        }
    }

    UIImage *resized = UIC_ResizeImage(image, size);
    if (!resized) return nil;

#if TARGET_OS_OSX
    CGImageRef cgImage = [resized CGImageForProposedRect:NULL context:nil hints:nil];
#else
    CGImageRef cgImage = resized.CGImage;
#endif
    if (!cgImage) return nil;

    const size_t width = CGImageGetWidth(cgImage);
    const size_t height = CGImageGetHeight(cgImage);
    const size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);

    // Gather bytes
    CGDataProviderRef provider = CGImageGetDataProvider(cgImage);
    if (!provider) return nil;
    CFDataRef dataRef = CGDataProviderCopyData(provider);
    if (!dataRef) return nil;
    const UInt8 *bytes = CFDataGetBytePtr(dataRef);

    NSInteger threshold = (NSInteger)floor((CGFloat)height * 0.01);
    double proposed[4] = { -1.0, -1.0, -1.0, -1.0 };

    NSCountedSet *imageColors = [[NSCountedSet alloc] initWithCapacity:(width * height)];
    for (size_t x = 0; x < width; x++) {
        for (size_t y = 0; y < height; y++) {
            size_t pixel = y * bytesPerRow + x * 4;
            // Assume BGRA (alpha last), mirror Swift implementation
            UInt8 a = bytes[pixel + 3];
            if (a >= 127) {
                double r = bytes[pixel + 2];
                double g = bytes[pixel + 1];
                double b = bytes[pixel + 0];
                [imageColors addObject:@(UIC_PackRGB(r, g, b))];
            }
        }
    }

    // Sort by frequency (desc)
    NSMutableArray<UIImageColorsCounter *> *sorted = [NSMutableArray arrayWithCapacity:imageColors.count];
    for (NSNumber *num in imageColors) {
        NSInteger c = [imageColors countForObject:num];
        if (c > threshold) {
            [sorted addObject:[[UIImageColorsCounter alloc] initWithColor:num.doubleValue count:c]];
        }
    }
    [sorted sortUsingComparator:^NSComparisonResult(UIImageColorsCounter * _Nonnull a, UIImageColorsCounter * _Nonnull b) {
        if (a.count < b.count) return NSOrderedDescending;
        if (a.count > b.count) return NSOrderedAscending;
        return NSOrderedSame;
    }];

    UIImageColorsCounter *edge = sorted.count > 0 ? sorted.firstObject
                                                  : [[UIImageColorsCounter alloc] initWithColor:0 count:1];

    if (UIC_IsBlackOrWhite(edge.color) && sorted.count > 0) {
        for (NSUInteger i = 1; i < sorted.count; i++) {
            UIImageColorsCounter *next = sorted[i];
            if ((double)next.count / (double)edge.count > 0.3) {
                if (!UIC_IsBlackOrWhite(next.color)) {
                    edge = next;
                    break;
                }
            } else {
                break;
            }
        }
    }
    proposed[0] = edge.color;

    // Find text colors
    [sorted removeAllObjects];
    BOOL findDarkText = !UIC_IsDark(proposed[0]);

    for (NSNumber *num in imageColors) {
        double k = UIC_WithMinSaturation(num.doubleValue, 0.15);
        if (UIC_IsDark(k) == findDarkText) {
            NSInteger c = [imageColors countForObject:@(k)];
            [sorted addObject:[[UIImageColorsCounter alloc] initWithColor:k count:c]];
        }
    }
    [sorted sortUsingComparator:^NSComparisonResult(UIImageColorsCounter * _Nonnull a, UIImageColorsCounter * _Nonnull b) {
        if (a.count < b.count) return NSOrderedDescending;
        if (a.count > b.count) return NSOrderedAscending;
        return NSOrderedSame;
    }];

    for (UIImageColorsCounter *cnt in sorted) {
        double c = cnt.color;
        if (proposed[1] == -1.0) {
            if (UIC_IsContrasting(c, proposed[0])) {
                proposed[1] = c;
            }
        } else if (proposed[2] == -1.0) {
            if (!UIC_IsContrasting(c, proposed[0]) || !UIC_IsDistinct(proposed[1], c)) continue;
            proposed[2] = c;
        } else if (proposed[3] == -1.0) {
            if (!UIC_IsContrasting(c, proposed[0]) ||
                !UIC_IsDistinct(proposed[2], c) ||
                !UIC_IsDistinct(proposed[1], c)) continue;
            proposed[3] = c;
            break;
        }
    }

    BOOL darkBG = UIC_IsDark(proposed[0]);
    for (int i = 1; i <= 3; i++) {
        if (proposed[i] == -1.0) {
            proposed[i] = darkBG ? UIC_PackRGB(255, 255, 255) : UIC_PackRGB(0, 0, 0);
        }
    }

    UIImageColors *result = [[UIImageColors alloc] initWithBackground:UIC_ColorFromPacked(proposed[0])
                                                              primary:UIC_ColorFromPacked(proposed[1])
                                                            secondary:UIC_ColorFromPacked(proposed[2])
                                                               detail:UIC_ColorFromPacked(proposed[3])];

    CFRelease(dataRef);
    return result;
}

#pragma mark - Category

@implementation UIImage (UIImageColors)

- (void)getColorsWithCompletion:(void (^)(UIImageColors * _Nullable))completion {
    [self getColorsWithQuality:UIImageColorsQualityHigh completion:completion];
}

- (void)getColorsWithQuality:(UIImageColorsQuality)quality
                  completion:(void (^)(UIImageColors * _Nullable))completion {
    if (!completion) return;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        UIImageColors *colors = UIC_GetColors(self, quality);
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(colors);
        });
    });
}

- (UIImageColors * _Nullable)getColors {
    return [self getColorsWithQuality:UIImageColorsQualityHigh];
}

- (UIImageColors * _Nullable)getColorsWithQuality:(UIImageColorsQuality)quality {
    return UIC_GetColors(self, quality);
}

@end

NS_ASSUME_NONNULL_END
