//
//  TDAPIClient.m
//  Throwdown
//
//  Created by Andrew C on 2/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDAPIClient.h"
#import "AFNetworking.h"
#import "TDConstants.h"

@interface TDAPIClient ()

@property (strong, nonatomic) AFHTTPRequestOperationManager *httpManager;
@property (strong, nonatomic) AFHTTPRequestOperation *credentialsTask;

@end

@implementation TDAPIClient

+ (TDAPIClient *)sharedInstance
{
    static TDAPIClient *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[TDAPIClient alloc] init];
    });
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.httpManager = [AFHTTPRequestOperationManager manager];
    }
    return self;
}

- (void)dealloc
{
    self.httpManager = nil;
    self.credentialsTask = nil;
}

- (void)validateCredentials:(NSDictionary *)parameters callback:(void (^)(BOOL success))callback
{
    // cancels any previous request
    [self.credentialsTask cancel];
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/validate.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    self.credentialsTask = [self.httpManager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSNumber *valid = (NSNumber *)[response objectForKey:@"valid"];
            callback([valid boolValue]);
        } else {
            debug NSLog(@"ERROR in validation response, got: %@", [responseObject class]);
            callback(NO);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in validation call: %@", [error localizedDescription]);
        callback(NO);
    }];
}

- (void)signupUser:(NSDictionary *)userAttributes callback:(void (^)(BOOL success, NSDictionary *user))callback
{
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/users.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager POST:url parameters:@{@"user": userAttributes} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                callback([success boolValue], [response objectForKey:@"user"]);
            } else {
                callback(NO, nil);
            }
        } else {
            debug NSLog(@"ERROR in signup response, got: %@", [responseObject class]);
            callback(NO, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in signup call: %@", [error localizedDescription]);
        callback(NO, nil);
    }];
}

- (void)loginUser:(NSString *)email withPassword:(NSString *)password callback:(void (^)(BOOL success, NSDictionary *user))callback
{
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/users/sign_in.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager POST:url parameters:@{@"user": @{ @"email": email, @"password": password }} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                callback([success boolValue], [response objectForKey:@"user"]);
            } else {
                callback(NO, nil);
            }
        } else {
            debug NSLog(@"ERROR in signup response, got: %@", [responseObject class]);
            callback(NO, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in signup call: %@", [error localizedDescription]);
        callback(NO, nil);
    }];
}

- (void)logoutUser {
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/users/sign_out.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager DELETE:url parameters:nil success:nil failure:nil];
}


@end
