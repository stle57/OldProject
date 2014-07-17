//
//  TDUploadProgressDelegate.h
//  Throwdown
//
//  Created by Andrew C on 3/8/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TDUploadProgressDelegate <NSObject>
- (void)uploadFailed;
- (void)uploadComplete;
@optional
- (void)uploadDidUpdate:(CGFloat)progress;
@end

@protocol TDUploadProgressUIDelegate <NSObject>
- (void)setUploadProgressDelegate:(id<TDUploadProgressDelegate>)delegate;
- (BOOL)displayProgressBar;
- (void)uploadRetry;
@optional
- (CGFloat)totalProgress;
- (UIImage *)previewImage;
- (NSString *)progressTitle;
@end
