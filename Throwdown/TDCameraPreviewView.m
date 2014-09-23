//
//  TDCameraPreviewView.m
//  Throwdown
//
//  Created by Andrew C on 9/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDCameraPreviewView.h"

@implementation TDCameraPreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session {
    return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session {
    [(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}

@end
