//
//  TDMoreComments.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDMoreComments : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *moreImageView;
@property (weak, nonatomic) IBOutlet UILabel *moreLabel;

-(void)moreCount:(NSInteger)count;
@end
