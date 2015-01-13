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

- (id)init {
    self = [super init];
    if (self) {

    }
    
   // [self setAlpha:.92];
    return self;
}

- (void)setBackgroundImage:(BOOL)blurEffect {
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

        //dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
        dispatch_queue_t main = dispatch_get_main_queue();
        
        dispatch_async(main, ^{
            [self applyBlurOnImage];

        });

    }
}

- (void)blurImage:(CGFloat)xPosition {
    //UIImage *img = self.image;
    float percent = (xPosition / 395.0) *10;
    debug NSLog(@"percent=%f", percent);
    //dispatch_queue_t queue = dispatch_queue_create(kAsyncQueueLabel, NULL);
    dispatch_queue_t main = dispatch_get_main_queue();
    
    
    dispatch_async(main, ^{
            self.image = [UIImageEffects imageByApplyingBlurToImage:self.image withRadius:percent tintColor:[UIColor colorWithWhite:1 alpha:0] saturationDeltaFactor:1 maskImage:nil];
        
//        self.image = [self.image :percent tintColor:[UIColor colorWithWhite:.92 alpha:0] saturationDeltaFactor:1 maskImage:nil];
    });
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
    debug NSLog(@"about to blur image");
    CGFloat blurRadius = .9f;
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

- (void)unBlurImage {
    [self setBackgroundImage:NO];
}

//- (void)applyBlurOnImage1:(CGRect)frame{
//    float storedPercentageForRendering = (frame.origin.x / 375);
//
//    UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
//    UIImage *imageForThisBlur = self.image;
//
//
//    //We'll render this on a background thread.
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//    UIImage *blurImage = [UIImageEffects imageByApplyingBlurToImage:imageForThisBlur withRadius:storedPercentageForRendering tintColor:tintColor saturationDeltaFactor:.5 maskImage:nil];
//        
//        //Once rendered, we put it back on the main queue for display.
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            [self setImage:blurImage];
//        });
//    });
//}


- (void)applyBlurOnImage1:(CGRect)frame{
    UIImage *img =  [self blurredSnapshot];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [self setImage:img];
    });
}

-(UIImage *)blurredSnapshot
{
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, self.window.screen.scale);
    
    // There he is! The new API method
    [self drawViewHierarchyInRect:self.frame afterScreenUpdates:NO];
    
    // Get the snapshot
    UIImage *snapshotImage = self.image;
    
    // Now apply the blur effect using Apple's UIImageEffect category
    UIImage *blurredSnapshotImage = [snapshotImage applyBlurWithRadius:10. iterationsCount:1 tintColor:[UIColor colorWithWhite:1 alpha:.92] saturationDeltaFactor:1.1 maskImage:nil];
    
    // Or apply any other effects available in "UIImage+ImageEffects.h"
    // UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
    // UIImage *blurredSnapshotImage = [snapshotImage applyExtraLightEffect];
    
    // Be nice and clean your mess up
    UIGraphicsEndImageContext();
    
    return blurredSnapshotImage;
}

- (void)renderSlideAtCurrentOffset:(CGRect)frame
{
//    if (_currentPosition < 1) {
//        self.blurredImageView.hidden = YES;
//        self.backgroundImageView.hidden = NO;
//        self.blurredImageView.image = nil;
//        self.imageOfBackgroundLayer = nil;
//        _blurredImageView.transform = CGAffineTransformMakeTranslation(0, 0);
//        return;
//    }
    
    //NOTE: This version supports doesn't support live content. This will screenshot the view (and subviews) as it exists when the gesture starts. If you don't want live content behind it, its better to take an initial image and reuse it for subsequent renderings instead of capturing a new image every time. Otherwise you'll need to run the snapshot on the view for every frame....much slower.
    
//    if (!self.imageOfBackgroundLayer) {
//        
//        //Compute a new image of the active layer. It's an image view in this case, but this code will work for any UIView and its subviews.
//        UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 1.0);//We're blurring it. We don't need retina, so set the scale to 1.0.
//        [self drawViewHierarchyInRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height) afterScreenUpdates:YES];
//        //self.imageOfBackgroundLayer = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//    }
    
    //Apple uses a max blur radius of 40. (See ImageEffects) So we'll compute the percentage of blur radius from 40.
    float storedPercentageForRendering = (frame.origin.x / (float)395);
    debug NSLog(@"storedpercentage for rendering=%f", storedPercentageForRendering);
    UIImage *imageForThisBlur = self.image;
    
    //We'll render this on a background thread.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        int blurRadius = (int)ceilf((storedPercentageForRendering * 10.0));
        float saturation = (storedPercentageForRendering * 1.0) + 1.0;
        UIColor *currentTint = [UIColor colorWithWhite:1 alpha:.92];
        
        UIImage *resultImage = [UIImageEffects imageByApplyingBlurToImage:imageForThisBlur withRadius:blurRadius tintColor:currentTint saturationDeltaFactor:saturation maskImage:nil];
        
        //Once rendered, we put it back on the main queue for display.
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = resultImage;
            //self.transform = CGAffineTransformMakeTranslation(395 * storedPercentageForRendering, 0);
            
            self.hidden = NO;
           // self.backgroundImageView.hidden = YES;
        });
    });
}

@end
