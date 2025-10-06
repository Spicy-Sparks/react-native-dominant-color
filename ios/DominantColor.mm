#import "DominantColor.h"
#import "UIImageColors.h"

@implementation DominantColor
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(getColorPalette:(NSString *)imagePath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if (imagePath.length == 0) { resolve(nil); return; }

    void (^finishWithImage)(UIImage *) = ^(UIImage *image) {
        if (!image) { resolve(nil); return; }
            UIImageColors *colors = [image getColors];
    if (!colors) { resolve(nil); return; }

    // Helper to convert UIColor to hex string (#RRGGBB)
    NSString* (^HexFromColor)(UIColor *) = ^NSString* (UIColor *color) {
        CGFloat r = 0, g = 0, b = 0, a = 0;
        if (![color getRed:&r green:&g blue:&b alpha:&a]) {
            // Try converting to RGB color space
            CGColorRef cgColor = color.CGColor;
            size_t num = CGColorGetNumberOfComponents(cgColor);
            const CGFloat *components = CGColorGetComponents(cgColor);
            if (components && (num == 4 || num == 3)) {
                r = components[0];
                g = components[1];
                b = components[2];
            }
        }
        int ri = (int)lrint(r * 255.0);
        int gi = (int)lrint(g * 255.0);
        int bi = (int)lrint(b * 255.0);
        return [NSString stringWithFormat:@"#%02X%02X%02X", ri, gi, bi];
    };

    resolve(@{ @"platform": @"ios",
            @"background": HexFromColor(colors.background),
            @"primary": HexFromColor(colors.primary),
            @"secondary": HexFromColor(colors.secondary),
            @"detail": HexFromColor(colors.detail) });
    };
    
    // 1) Remote URL (http/https)
    if ([imagePath hasPrefix:@"http://"] || [imagePath hasPrefix:@"https://"]) {
    NSURL *url = [NSURL URLWithString:imagePath];
    if (!url) { resolve(nil); return; }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error) {
        if (error || !data) { resolve(nil); return; }
        UIImage *img = [UIImage imageWithData:data];
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            finishWithImage(img);
        });
    }];
    [task resume];
    return;
    }

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        UIImage *image = nil;

        // 2) Data URI (base64)
        if ([imagePath hasPrefix:@"data:image"]) {
            NSRange commaRange = [imagePath rangeOfString:@","];
            if (commaRange.location != NSNotFound && NSMaxRange(commaRange) < imagePath.length) {
                NSString *base64String = [imagePath substringFromIndex:NSMaxRange(commaRange)];
                NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
                if (data) { image = [UIImage imageWithData:data]; }
            }
        }

        // 3) File URL / path
        if (!image) {
            NSURL *maybeURL = [NSURL URLWithString:imagePath];
            if (maybeURL && maybeURL.isFileURL) { image = [UIImage imageWithContentsOfFile:maybeURL.path]; }
            else if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) { image = [UIImage imageWithContentsOfFile:imagePath]; }
        }

        // 4) Bundle image
        if (!image) { image = [UIImage imageNamed:imagePath]; }

        finishWithImage(image);
    });
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeDominantColorSpecJSI>(params);
}

@end
