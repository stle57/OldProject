//
//  TDTextViewControllerHelper.m
//  Throwdown
//
//  Created by Stephanie Le on 7/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDTextViewControllerHelper.h"
#import "TDUserAPI.h"

@implementation TDTextViewControllerHelper

+(int)findUsernameLength:(NSString*)currentText{
    int userNameLength = 0;
    for(int i = (int)currentText.length-1; i >=0 ; i--){
        NSRange range = NSMakeRange(i, 1);
        if([[currentText substringWithRange:(range)] isEqualToString:@" "]) {
            break;
        } else {
            userNameLength++;
        }
    }

    return userNameLength;
}

+(NSString*)getUserNameList:(NSString*)text length:(int)userNameLength{
    NSString *usernameFilter = nil;

    // Check for "@" and modify the userName string
    NSString* filterStr=[text substringFromIndex:(text.length-userNameLength)];
    debug NSLog(@"userNameFilter=%@", filterStr);

    // Take care of case where filterStr begins with return
    // character(\n) 
    if([filterStr hasPrefix:@"\n@"])
        filterStr = [filterStr substringFromIndex:1];

    if ([[filterStr substringToIndex:(1)] isEqualToString:@"@"]) {
        usernameFilter = [filterStr substringWithRange:(NSMakeRange(1, filterStr.length-1))];
        debug NSLog(@"userNameFilter after @=%@", usernameFilter);
    }
    return usernameFilter;
}

@end
