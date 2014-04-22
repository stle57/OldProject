//
//  TDActivityViewController.h
//  Throwdown
//
//  Created by Andrew C on 4/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#import <MessageUI/MessageUI.h>

@interface TDActivityViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>
{

}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)unwindToRoot;
-(IBAction)feedbackButton:(id)sender;
@end
