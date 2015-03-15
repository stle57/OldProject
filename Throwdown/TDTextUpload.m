
//
//  TDTextUpload.m
//  Throwdown
//
//  Created by Andrew C on 7/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDTextUpload.h"
#import "TDPostAPI.h"

@interface TDTextUpload ()

@property (nonatomic) NSString *comment;
@property (nonatomic) BOOL isPR;
@property (nonatomic) TDPostPrivacy visibility;
@property (nonatomic) NSDictionary *location;
@end

@implementation TDTextUpload

- (instancetype)initWithComment:(NSString *)comment isPR:(BOOL)isPR visibility:(TDPostPrivacy)visibility location:(NSDictionary *)location{
    self = [super init];
    if (self) {
        self.comment = comment;
        self.isPR = isPR;
        self.visibility = visibility;
        self.location = [location copy];
    }
    return self;
}

- (void)dealloc {
    [self clean];
}

- (void)clean {
    self.delegate = nil;
    self.comment = nil;
}

- (void)upload {
    [[TDPostAPI sharedInstance] addPost:nil comment:self.comment isPR:self.isPR kind:@"text" userGenerated:NO sharingTo:self.shareOptions visibility:self.visibility location:self.location success:^(NSDictionary *response) {
        [self uploadComplete];
    } failure:^{
        [self uploadFailed];
    }];
}

- (void)uploadComplete {
    if (self.delegate) {
        [self.delegate uploadComplete];
    }
    [self clean];
}

- (void)uploadFailed {
    if (self.delegate) {
        [self.delegate uploadFailed];
    }
}

#pragma mark TDUploadProgressUIDelegate

- (BOOL)displayProgressBar {
    return NO;
}

- (void)setUploadProgressDelegate:(id<TDUploadProgressDelegate>)delegate {
    self.delegate = delegate;
    [self upload];
}

- (NSString *)progressTitle {
    return self.comment;
}

- (void)uploadRetry {
    [self upload];
}


@end
