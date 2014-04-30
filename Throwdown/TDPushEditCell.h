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
-(void)switchOnFromRow:(NSInteger)row;
-(void)switchOffFromRow:(NSInteger)row;
@end

@interface TDPushEditCell : UITableViewCell
{
    id <TDPushEditCellDelegate> __unsafe_unretained delegate;
    CGFloat bottomLineOrigY;
    NSInteger rowNumber;
}

@property (nonatomic, assign) id <TDPushEditCellDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UILabel *longTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIView *topLine;
@property (weak, nonatomic) IBOutlet UISwitch *aSwitch;
@property (nonatomic, assign) CGFloat bottomLineOrigY;
@property (nonatomic, assign) NSInteger rowNumber;

-(IBAction)switch:(id)sender;

@end
