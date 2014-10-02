//
//  TDAddressBookAPI.m
//  Throwdown
//
//  Created by Stephanie Le on 10/2/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDAddressBookAPI.h"
#import "TDContactInfo.h"

@interface TDAddressBookAPI ()

@property (nonatomic) NSMutableArray* contactList;

@end

@implementation TDAddressBookAPI
+ (TDAddressBookAPI *)sharedInstance {
    static TDAddressBookAPI *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[TDAddressBookAPI alloc] init];
    });
    return _sharedInstance;
}

- (id) init {
    self = [super init];
    if (self) {
        [self copyAddressBook];
    }
    return self;
}

- (void)copyAddressBook {
    CFErrorRef * err = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, err);
    
    __block BOOL accessGranted = NO;
    
    if (ABAddressBookRequestAccessWithCompletion != NULL) { // We are on iOS 6
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(semaphore);
        });
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    else { // We are on iOS 5 or Older
        accessGranted = YES;
        [self addContactsToAddressBook:addressBook];
    }
    
    if (accessGranted) {
        [self addContactsToAddressBook:addressBook];
    }
}

- (void)addContactsToAddressBook:(ABAddressBookRef)addressBook {
    if (addressBook != nil) {
        ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
        NSArray *contactArray = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, kABPersonSortByLastName));
        // sort again because users may have inputed the full name into the first name
        //debug NSLog(@"count of contactArray before sort=%ld", (unsigned long)[contactArray count]);
        //contactArray=[self sortByLastNameForContacts:contactArray];
        //debug NSLog(@"count of contactArray AFTER sort=%ld", (unsigned long)[contactArray count]);
        
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < [contactArray count]; i++)
        {
            TDContactInfo *contactInfo = [[TDContactInfo alloc] init];
            
            ABRecordRef contactPerson = (__bridge ABRecordRef)contactArray[i];
            
            contactInfo.id = ABRecordGetRecordID(contactPerson);
            contactInfo.firstName = CFBridgingRelease(ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty));
            contactInfo.lastName =  CFBridgingRelease(ABRecordCopyValue(contactPerson, kABPersonLastNameProperty));
            if (contactInfo.lastName == nil) {
                contactInfo.fullName = [NSString stringWithFormat:@"%@", contactInfo.firstName];
            } else {
                contactInfo.fullName = [NSString stringWithFormat:@"%@ %@", contactInfo.firstName, contactInfo.lastName];
            }
            
            if(contactInfo.fullName.length == 0) {
                debug NSLog(@"====>not adding this contact");
                break;
            }
            ABMultiValueRef emails = ABRecordCopyValue(contactPerson, kABPersonEmailProperty);
            NSUInteger j = 0;
            for (j = 0; j < ABMultiValueGetCount(emails); j++)
            {
                NSString *email = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emails, j);
                [contactInfo.emailList addObject:email];
            }
            
            ABMultiValueRef phoneNumbers = ABRecordCopyValue(contactPerson, kABPersonPhoneProperty);
            NSUInteger p = 0;
            for (p = 0; p < ABMultiValueGetCount(phoneNumbers); p++)
            {
                NSString *phoneNumber = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phoneNumbers, p);
                [contactInfo.phoneList addObject:phoneNumber];
            }
            
            if (ABPersonHasImageData(contactPerson) == YES) {
                CFDataRef ref = ABPersonCopyImageData(contactPerson);
                contactInfo.contactPicture = [[UIImage alloc] initWithData:(__bridge NSData *)(ref)];
            }
            
            
            [tempArray addObject:contactInfo];
        }
        
        self.contactList = [tempArray copy];
        
    }
    
}

- (NSArray*)getContactList {
    debug NSLog(@"contactList count=%lu", (unsigned long)[self.contactList count]);
    return self.contactList;
}

//Method to sort by last name for Contacts
-(NSArray*)sortByLastNameForContacts:(NSArray*)sortArray
{
    sortArray = [sortArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first,*second;int count = 0;
        
        first=[NSString stringWithString:[[NSString stringWithFormat:@"%@",(__bridge_transfer NSString *)ABRecordCopyCompositeName((__bridge ABRecordRef)(a))] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        second=[NSString stringWithString:[[NSString stringWithFormat:@"%@",(__bridge_transfer NSString *)ABRecordCopyCompositeName((__bridge ABRecordRef)(b))] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        
        first = [self fetchLastName:first];
        second=[self fetchLastName:second];
        count++;
        
        return [first compare:second options:NSCaseInsensitiveSearch];
    }];
    return  sortArray;
}

-(NSString*)fetchLastName:(NSString*)lastName
{
    lastName=[lastName stringByReplacingOccurrencesOfString:@"." withString:@" "];
    NSRange range=[lastName rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet] options:NSBackwardsSearch];
    range.length=range.location;
    range.location=0;
    lastName= ([lastName rangeOfString:@" " options:NSBackwardsSearch range:range].location==NSNotFound)? [NSString stringWithFormat:@" %@",lastName]:[lastName substringFromIndex:[lastName rangeOfString:@" " options:NSBackwardsSearch range:range].location];
    return lastName;
    
}
@end
