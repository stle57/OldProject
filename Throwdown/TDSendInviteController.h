//
//  TDSendInviteController.h
//  Throwdown
//
//  Created by Stephanie Le on 9/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDActivityIndicator.h"
#import "TDConstants.h"

#define TOP_BOTTOM_HEADER1_MARGIN 25
#define TOP_MARGIN_HEADER2        11
#define MIDDLE_MARGIN_HEADER2     38
@interface TDSendInviteController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet TDActivityIndicator *activityIndicator;
@property (nonatomic) NSString* sender;
@property (nonatomic) NSMutableArray *headerLabels;

- (IBAction)closeButtonHit:(id)sender;
- (IBAction)sendButtonHit:(id)sender;
- (void)setValuesForSharing:(NSArray *)contacts senderName:(NSString*)senderName;
- (NSString*)convertInviteType:(id)inviteType;
- (NSArray *)contacts;
@end
