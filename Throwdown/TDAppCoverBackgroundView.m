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

@implementation TDAppCoverBackgroundView

- (id)init {
    self = [super init];
    if (self) {

    }
    
   // [self setAlpha:.92];
    return self;
}

- (void)setBackgroundImage {
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
}

//- (void)blurImage {
////    CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
////    [gaussianBlurFilter setDefaults];
////    [gaussianBlurFilter setValue:[CIImage imageWithCGImage:[self.image CGImage]] forKey:kCIInputImageKey];
////    [gaussianBlurFilter setValue:@10 forKey:kCIInputRadiusKey];
////
////    CIImage *outputImage = [gaussianBlurFilter outputImage];
////    CIContext *context   = [CIContext contextWithOptions:nil];
////    CGRect rect          = [outputImage extent];
////
////    // these three lines ensure that the final image is the same size
////
////    rect.origin.x        += (rect.size.width  - self.image.size.width ) / 2;
////    rect.origin.y        += (rect.size.height - self.image.size.height) / 2;
////    rect.size            =  self.image.size;
////
////    CGImageRef cgimg     = [context createCGImage:outputImage fromRect:rect];
////    [self setImage:[UIImage imageWithCGImage:cgimg]];
////    CGImageRelease(cgimg);
//    //GPUImageGaussianBlurFilter * filter = [[GPUImageGaussianBlurFilter alloc] init];
//    //filter.blurSize = 0.5;
//    //UIImage * blurred = [filter imageByFilteringImage:self.image];
//    
//    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
//    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
//    effectView.frame = self.bounds;
//    [self addSubview:effectView];
//    
//    UIView *backgroundView = [[UIView alloc]init];
//    backgroundView.frame = self.bounds;
//    backgroundView.backgroundColor = [UIColor whiteColor];
//    [backgroundView setAlpha:.08];
//    [self addSubview:backgroundView];
//    
//
//}

//- (void)applyBlurOnImage{
//    debug NSLog(@"about to apply blur image");
//    GPUImageGaussianBlurFilter *blurFilter =
//        [[GPUImageGaussianBlurFilter alloc] init];
//    blurFilter.blurRadiusInPixels = 10;
//    [self setImage:[blurFilter imageByFilteringImage:self.image]];
//}

- (void)applyBlurOnImage{
    debug NSLog(@"about to blue image");
    CGFloat blurRadius = 10.f;
    if ((blurRadius < 0.0f) || (blurRadius > 1.0f)) {
        blurRadius = 0.5f;
    }
    int boxSize = (int)(blurRadius * 100);
    boxSize -= (boxSize % 2) + 1;
    CGImageRef rawImage = self.image.CGImage;
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
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data, outBuffer.width, outBuffer.height, 8, outBuffer.rowBytes, colorSpace, CGImageGetBitmapInfo(self.image.CGImage));
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    [self setImage:[UIImage imageWithCGImage:imageRef]];
    debug NSLog(@"done blurring image");
    //clean up CGContextRelease(ctx); CGColorSpaceRelease(colorSpace); free(pixelBuffer); CFRelease(inBitmapData); CGImageRelease(imageRef); return returnImage;
}
@end
