//
//  TDPushEditCell.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/30/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDPushEditCellDelegate <NSObject>
@optional
- (void)switchValue:(NSNumber *)value forIndexPath:(NSIndexPath *)indexPath;
@end

@interface TDPushEditCell : UITableViewCell

@property (nonatomic, weak) id <TDPushEditCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *longTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIView *topLine;
@property (weak, nonatomic) IBOutlet UISwitch *aSwitch;
@property (nonatomic) CGFloat bottomLineOrigY;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic) NSIndexPath *indexPath;

- (IBAction)switch:(id)sender;

@end
