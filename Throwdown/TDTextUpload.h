//
//  TDTextUpload.h
//  Throwdown
//
//  Created by Andrew C on 7/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDUploadProgressDelegate.h"
#import "TDConstants.h"

@interface TDTextUpload : NSObject <TDUploadProgressUIDelegate>

@property (nonatomic, assign) id<TDUploadProgressDelegate> delegate;
@property (nonatomic) NSArray *shareOptions;

- (instancetype)initWithComment:(NSString *)comment isPR:(BOOL)isPR visibility:(TDPostPrivacy)visibility location:(NSDictionary*)location;

#pragma mark TDUploadProgressUIDelegate
- (void)setUploadProgressDelegate:(id<TDUploadProgressDelegate>)delegate;
- (void)uploadRetry;
- (BOOL)displayProgressBar;

@end
