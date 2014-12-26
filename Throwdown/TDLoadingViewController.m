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

@interface TDLoadingViewController ()
@property (nonatomic) TDLoadingView *loadingView1;
@property (nonatomic) TDLoadingView *loadingView2;
@property (nonatomic) TDLoadingView *loadingView3;
@end

@implementation TDLoadingViewController

- (void)dealloc {
    self.loadingView1 = nil;
    self.loadingView2 = nil;
    self.loadingView3 = nil;
}

- (void)viewDidLoad {
    debug NSLog(@"inside TDLoadingViewController:viewDidLoad");
    [super viewDidLoad];
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

    //self.loadingInfoView.frame = CGRectMake(SCREEN_WIDTH/2 - 270/2, SCREEN_HEIGHT/2 - 318/2, 270, 318);
    
    self.loadingView1 = [TDLoadingView loadingView];
    self.loadingView1.frame = CGRectMake(SCREEN_WIDTH/2 - 270/2, SCREEN_HEIGHT/2 - 318/2, 270, 318);
    [self.loadingView1 setViewType:kView1_Loading];
    [self.view addSubview:self.loadingView1];
    self.loadingView1.alpha = 0;
   // self.loadingView1.hidden = YES;
    
    self.loadingView2 = [TDLoadingView loadingView];
    self.loadingView2.frame = CGRectMake(SCREEN_WIDTH/2 - 270/2, SCREEN_HEIGHT/2 - 318/2, 270, 318);
    [self.loadingView2 setViewType:kView2_Loading];
    [self.view addSubview:self.loadingView2];
    self.loadingView2.alpha = 0;
    //self.loadingView2.hidden = YES;
    
    self.loadingView3 = [TDLoadingView loadingView];
    self.loadingView3.frame = CGRectMake(SCREEN_WIDTH/2 - 270/2, SCREEN_HEIGHT/2 - 318/2, 270, 318);
    [self.loadingView3 setViewType:kView3_Loading];
    [self.view addSubview:self.loadingView3];
    self.loadingView3.alpha = 0;
    //self.loadingView3.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    debug NSLog(@"inside TDLoadingViewController:viewAppearLoad");

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
    debug NSLog(@"===========>showData");
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                            animations:^{
                                self.loadingView1.alpha = 1.0;
                                [self.loadingView1 startAnimating];
                        }
                     completion:^(BOOL finished){
                         // code to run when animation completes
                         // (in this case, another animation:)
                         [UIView animateWithDuration:0.2
                                               delay:2
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              self.loadingView1.alpha = 0;
                                              self.loadingView2.alpha = 1;
                                          }
                                          completion:^(BOOL finished){  
                                              [UIView animateWithDuration:0.2
                                                                    delay:2
                                                                  options:UIViewAnimationOptionCurveEaseIn
                                                               animations:^{
                                                                   self.loadingView2.alpha = 0;
                                                                   self.loadingView3.alpha = 1;
                                                               }
                                                               completion:^(BOOL finished){
                                                                   
                                                               }];
                                          }];
                     }];
    
//    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
//       // self.loadingView1.hidden = NO;
//    }completion:^(BOOL finished) {
//        debug NSLog(@"show view2");
//        [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
//            self.loadingView1.hidden = NO;
//            //self.loadingView2.hidden = NO;
//        } completion:^(BOOL finished) {
//            self.loadingView1.hidden = YES;
//            self.loadingView2.hidden = NO;
//            //debug NSLog(@"show view3");
////            [UIView animateWithDuration:2 animations:^{
////                [self.loadingView setViewType:kView3_Loading];
////                
////            } completion:^(BOOL finished) {
////                debug NSLog(@"done show home view");
////            }];
//        }];
//    }];
}
@end
