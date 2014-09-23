//
//  TDCameraPreviewView.h
//  Throwdown
//
//  Created by Andrew C on 9/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface TDCameraPreviewView : UIView

@property (nonatomic) AVCaptureSession *session;

@end
