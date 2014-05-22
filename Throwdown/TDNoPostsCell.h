//
//  TDNoPostsCell.h
//  Throwdown
//
//  Created by Andrew B on 4/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDNoPostsCellDelegate <NSObject>

@end

@interface TDNoPostsCell : UITableViewCell

@property (nonatomic, assign) id <TDNoPostsCellDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UILabel *noPostsLabel;
@property (weak, nonatomic) IBOutlet UIView *view;

@end
