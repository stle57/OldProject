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
- (void)emailValue:(BOOL)value forIndexPath:(NSIndexPath *)indexPath;
- (void)pushValue:(BOOL)value forIndexPath:(NSIndexPath *)indexPath;
@end

@interface TDPushEditCell : UITableViewCell

@property (nonatomic, weak) id <TDPushEditCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *longTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIView *topLine;
@property (weak, nonatomic) IBOutlet UIButton *pushButton;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (nonatomic) CGFloat bottomLineOrigY;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic) NSIndexPath *indexPath;
@property (nonatomic) BOOL emailValue;
@property (nonatomic) BOOL pushValue;

- (IBAction)switch:(id)sender;
- (IBAction)emailButtonPressed:(UIButton*)sender;
- (IBAction)pushButtonPressed:(UIButton*)sender;
@end
