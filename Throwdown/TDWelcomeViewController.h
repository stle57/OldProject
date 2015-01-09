//
//  TDWelcomeViewController.h
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDWelcomeViewController : UIViewController
{

}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *snippetLabel;
@property (nonatomic, assign, readwrite) BOOL editViewOnly;

- (void)showHomeController;
- (void)showGuestController;
@end
