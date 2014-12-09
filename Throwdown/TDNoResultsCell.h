//
//  TDNoResultsCell.h
//  Throwdown
//
//  Created by Stephanie Le on 12/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDNoResultsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *noMatchesLabel;

@end
