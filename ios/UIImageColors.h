#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
typedef NSImage UIImage;
typedef NSColor UIColor;
#else
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, UIImageColorsQuality) {
    UIImageColorsQualityLowest  = 50,   // 50px
    UIImageColorsQualityLow     = 100,  // 100px
    UIImageColorsQualityHigh    = 250,  // 250px
    UIImageColorsQualityHighest = 0     // No scale
};

@interface UIImageColors : NSObject
@property (nonatomic, strong, readonly) UIColor *background;
@property (nonatomic, strong, readonly) UIColor *primary;
@property (nonatomic, strong, readonly) UIColor *secondary;
@property (nonatomic, strong, readonly) UIColor *detail;

- (instancetype)initWithBackground:(UIColor *)background
                           primary:(UIColor *)primary
                         secondary:(UIColor *)secondary
                            detail:(UIColor *)detail NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

@interface UIImage (UIImageColors)

/// Async (main-thread callback). Default quality = High.
- (void)getColorsWithCompletion:(void(^)(UIImageColors * _Nullable colors))completion;
- (void)getColorsWithQuality:(UIImageColorsQuality)quality
                  completion:(void(^)(UIImageColors * _Nullable colors))completion;

/// Sync. Default quality = High.
- (UIImageColors * _Nullable)getColors;
- (UIImageColors * _Nullable)getColorsWithQuality:(UIImageColorsQuality)quality;

@end

NS_ASSUME_NONNULL_END
