//
//  TDAppCoverBackgroundView.m
//  Throwdown
//
//  Created by Stephanie Le on 12/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDAppCoverBackgroundView.h"
#import "GPUImage.h"
#import <Accelerate/Accelerate.h>
#import "UIImage+BlurredFrame.h"
#import "UIImage+ImageEffects.h"
#import "UIImageEffects.h"
@implementation TDAppCoverBackgroundView

- (void)setBackgroundImage:(BOOL)blurEffect editingViewOnly:(BOOL)editViewingOnly{
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        [self setImage:[UIImage imageNamed:@"AppCover_iPhone4s"]];
        [self setFrame:CGRectMake(0, 0, [UIImage imageNamed:@"AppCover_iPhone4s"].size.width, [UIImage imageNamed:@"AppCover_iPhone4s"].size.height)];
    } else if ([UIScreen mainScreen].bounds.size.height == 568) {
        [self setImage:[UIImage imageNamed:@"AppCover_iPhone5"]];
        [self setFrame:CGRectMake(0, 0, [UIImage imageNamed:@"AppCover_iPhone5"].size.width, [UIImage imageNamed:@"AppCover_iPhone5"].size.height)];
    } else if ([UIScreen mainScreen].bounds.size.height == 667) {
        [self setImage:[UIImage imageNamed:@"AppCover_iPhone6"]];
        [self setFrame:CGRectMake(0, 0, [UIImage imageNamed:@"AppCover_iPhone6"].size.width, [UIImage imageNamed:@"AppCover_iPhone6"].size.height)];
    } else {
        [self setImage:[UIImage imageNamed:@"AppCover_iPhone6plus"]];
        [self setFrame:CGRectMake(0, 0, [UIImage imageNamed:@"AppCover_iPhone6plus"].size.width, [UIImage imageNamed:@"AppCover_iPhone6plus"].size.height)];
    }
    
    if (blurEffect){
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

        
        dispatch_async(queue, ^ {
            UIImage *img = [UIImageEffects imageByApplyingBlurToImage:self.image withRadius:20 tintColor:[UIColor colorWithWhite:1 alpha:.87] saturationDeltaFactor:1 maskImage:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = img;
                if (editViewingOnly) {
                    self.alpha = 1;
                } else {
                    self.alpha = 0;
                }
            });
        });
    }
}


- (UIImage *)applyBlurOnImage: (UIImage *)imageToBlur
                   withRadius:(CGFloat)blurRadius {
    if ((blurRadius <= 0.0f) || (blurRadius > 1.0f)) {
        blurRadius = 0.5f;
    }
    NSLog(@"inside applyBlurOnImage");
    int boxSize = (int)(blurRadius * 100);
    boxSize -= (boxSize % 2) + 1;
    
    CGImageRef rawImage = imageToBlur.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(rawImage);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    inBuffer.width = CGImageGetWidth(rawImage);
    inBuffer.height = CGImageGetHeight(rawImage);
    inBuffer.rowBytes = CGImageGetBytesPerRow(rawImage);
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(rawImage) * CGImageGetHeight(rawImage));
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(rawImage);
    outBuffer.height = CGImageGetHeight(rawImage);
    outBuffer.rowBytes = CGImageGetBytesPerRow(rawImage);
    
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL,
                                       0, 0, boxSize, boxSize, NULL,
                                       kvImageEdgeExtend);
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             CGImageGetBitmapInfo(imageToBlur.CGImage));
    
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    CFRelease(inBitmapData);
    CGImageRelease(imageRef);
    
    NSLog(@"returning image on applyBlurOnImage");
    return returnImage;
}
@end
