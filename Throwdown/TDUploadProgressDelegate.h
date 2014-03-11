//
//  TDUploadProgressDelegate.h
//  Throwdown
//
//  Created by Andrew C on 3/8/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TDUploadProgressDelegate <NSObject>

- (void)uploadDidUpdate:(CGFloat)progress;
- (void)uploadFailed;
- (void)uploadComplete;

@end
