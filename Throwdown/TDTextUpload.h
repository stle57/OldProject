//
//  TDTextUpload.h
//  Throwdown
//
//  Created by Andrew C on 7/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDUploadProgressDelegate.h"

@interface TDTextUpload : NSObject <TDUploadProgressUIDelegate>

@property (nonatomic, assign) id<TDUploadProgressDelegate> delegate;

- (instancetype)initWithComment:(NSString *)comment isPR:(BOOL)isPR;

#pragma mark TDUploadProgressUIDelegate
- (void)setUploadProgressDelegate:(id<TDUploadProgressDelegate>)delegate;
- (void)uploadRetry;
- (BOOL)displayProgressBar;

@end
