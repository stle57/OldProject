//
//  TDLoadingViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 12/20/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDLoadingViewController.h"
#import "TDConstants.h"
#import "TDLoadingView.h"
#import "TDViewControllerHelper.h"
#import "TDCurrentUser.h"
#import "TDAPIClient.h"
#import "TDGuestUser.h"

@interface TDLoadingViewController ()
@property (nonatomic, retain) TDLoadingView *loadingView1;
@property (nonatomic, retain) TDLoadingView *loadingView2;
@property (nonatomic, retain) TDLoadingView *loadingView3;
@property (nonatomic) BOOL minAnimationReached;
@property (nonatomic) BOOL loadedData;
@property (nonatomic) TDGuestUserProfileViewController *guestViewController;
@property (nonatomic) NSDictionary *guestPosts;
@end

@implementation TDLoadingViewController

- (void)dealloc {
    self.loadingView1 = nil;
    self.loadingView2 = nil;
    self.loadingView3 = nil;
    self.guestViewController = nil;
    self.guestPosts = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.minAnimationReached = NO;
    self.loadedData = NO;

    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.view.backgroundColor = [UIColor clearColor];
    
    self.loadingView1 = [TDLoadingView loadingView:kView1_Loading];
    self.loadingView1.frame = CGRectMake(SCREEN_WIDTH/2 - 270/2, SCREEN_HEIGHT/2 - 318/2, 270, 318);
    [self.loadingView1 setViewType:kView1_Loading];
    [self.view addSubview:self.loadingView1];
    self.loadingView1.alpha = 0;
    
    self.loadingView2 = [TDLoadingView loadingView:kView2_Loading];
    self.loadingView2.frame = CGRectMake(SCREEN_WIDTH/2 - 270/2, SCREEN_HEIGHT/2 - 318/2, 270, 318);
    [self.loadingView2 setViewType:kView2_Loading];
    [self.view addSubview:self.loadingView2];
    self.loadingView2.alpha = 0;
    
    self.loadingView3 = [TDLoadingView loadingView:kView3_Loading];
    self.loadingView3.frame = CGRectMake(SCREEN_WIDTH/2 - 270/2, SCREEN_HEIGHT/2 - 318/2, 270, 318);
    [self.loadingView3 setViewType:kView3_Loading];
    [self.view addSubview:self.loadingView3];
    self.loadingView3.alpha = 0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)showData {
    if ([TDCurrentUser sharedInstance].userId != nil) {
        [[TDCurrentUser sharedInstance] didAskForGoalsInitially:YES];
        [[TDCurrentUser sharedInstance] didAskForGoalsFinal:YES];
    }
    [self sendDataToServer];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                            animations:^{
                                self.loadingView1.alpha = 1.0;
                        }
                     completion:^(BOOL finished){
                         // code to run when animation completes
                         // (in this case, another animation:)
                         [UIView animateWithDuration:.5
                                               delay:3.5
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.loadingView1.alpha = 0;
                                              self.loadingView2.alpha = 1;
                                          }
                                          completion:^(BOOL finished){
                                              [self performSelector:@selector(setMinReached) withObject:nil afterDelay:3.0];
                                          }];
                     }];
}


- (void)saveDataForUser {
    [[TDAPIClient sharedInstance] saveGoalsAndInterestsForUser:^(BOOL success) {
        if (success) {
            [self endAnimation];
        } else {
            [self endAnimation];
            [TDViewControllerHelper showAlertMessage:@"There was an error, please try again." withTitle:@"Error"];
        }
    }];
}


- (void)saveDataForGuest {
    NSLog(@"inside saveDataForGuest");
    [[TDAPIClient sharedInstance] saveGoalsAndInterestsForGuest:^(BOOL success, NSDictionary *posts) {
        if (success) {
            [self endAnimation];
            self.guestPosts = posts;
        } else {
             NSLog(@"error inside saveDataForGuest, endAnimation");
            [self endAnimation];
        }
    }];
}
- (void)sendDataToServer{
    if ([[TDCurrentUser sharedInstance] isLoggedIn]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self saveDataForUser];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.loadedData = NO;
            });

        });
    } else {
        NSLog(@"get guest view in background thread");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self saveDataForGuest];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.loadedData = NO;
            });
        });
    }

}
- (void)loadCorrectView {
    if ([[TDCurrentUser sharedInstance] didAskForGoalsFinal] && [[TDCurrentUser sharedInstance] isLoggedIn] && self.delegate && [self.delegate respondsToSelector:@selector(loadHomeView)]){

        [self.delegate loadHomeView];
    } else {
        // This is for guest user only;
        if (self.delegate && [self.delegate respondsToSelector:@selector(loadGuestView:)]) {
            if (self.guestViewController.errorLoading) {
                NSLog(@"...inside loadCorrectView, guestViewController had error, show alert");
                [TDViewControllerHelper showAlertMessage:@"There was an error, please try again." withTitle:@"Error"];
            } else {
                if (self.guestPosts) {
                    [self.delegate loadGuestView:self.guestPosts];
                }
            }
        }
    }
}

- (void)endAnimation {
    self.loadedData = YES;
    [self animateToLastView];
}

- (void)setMinReached {
    self.minAnimationReached = YES;
    [self animateToLastView];
}
- (void)animateToLastView {
    if (self.minAnimationReached && self.loadedData) {
        if (self.guestPosts || [[TDCurrentUser sharedInstance] isLoggedIn]) {
        [UIView animateWithDuration:.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.loadingView2.alpha = 0;
                             self.loadingView3.alpha = 1;
                         }
                         completion:^(BOOL finished){
                             [self performSelector:@selector(loadCorrectView) withObject:nil afterDelay:2.0];
                         }];
        } else {
            NSLog(@"guest post count is empty or user is not logged in");
            [UIView animateWithDuration:.5
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.loadingView2.alpha = 0;
                             }
                             completion:^(BOOL finished){
                                NSLog(@"error inside animateToLastView, show alert message, then load interests view");
                                 [TDViewControllerHelper showAlertMessage:@"There was an error, please try again." withTitle:@"Error"];
                                 [self.delegate loadInterestsView];
                             }];

        }
    }
}
@end
