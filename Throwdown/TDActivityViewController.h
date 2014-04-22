//
//  TDActivityViewController.h
//  Throwdown
//
//  Created by Andrew C on 4/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDActivityViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{

}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)unwindToRoot;
@end
