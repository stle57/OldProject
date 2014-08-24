
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
@property (nonatomic) NSDictionary *postOptions;

@end

@implementation TDTextUpload

- (instancetype)initWithComment:(NSString *)comment isPR:(BOOL)isPR {
    self = [super init];
    if (self) {
        self.comment = comment;
        self.isPR = isPR;
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
    if (self.postOptions) {
        [self shareOrComplete];
    } else {
        [[TDPostAPI sharedInstance] addPost:nil comment:self.comment isPR:self.isPR kind:@"text" userGenerated:NO sharingTo:self.shareOptions success:^(NSDictionary *response) {
            self.postOptions = [response objectForKey:@"share_options"];
            [self shareOrComplete];
        } failure:^{
            [self uploadFailed];
        }];
    }
}

- (void)shareOrComplete {
    if (self.shareOptions && [self.shareOptions count] > 0) {
        [[TDPostAPI sharedInstance] sharePost:self.postOptions toNetworks:self.shareOptions success:^{
            [self uploadComplete];
        } failure:^{
            [self uploadFailed];
        }];
    } else {
        [self uploadComplete];
    }
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
