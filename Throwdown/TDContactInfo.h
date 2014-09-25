//
//  TDContactInfo.h
//  Throwdown
//
//  Created by Stephanie Le on 9/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDConstants.h"

@interface TDContactInfo : NSObject

@property (nonatomic) NSInteger id;
@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;
@property (nonatomic) NSMutableArray *phoneList;
@property (nonatomic) NSMutableArray *emailList;
@property (nonatomic) UIImage *contactPicture;
@property (nonatomic) NSString *fullName;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *selectedData;
@property (nonatomic) kInviteType inviteType;
@property (nonatomic) BOOL following;
@end
