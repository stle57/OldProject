//
//  TDActivityCell.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDActivityCell : UITableViewCell
{
}

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

-(void)startSpinner;
@end
