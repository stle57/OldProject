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
@property (nonatomic) ABAddressBookRef addressBook;
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

void MyAddressBookExternalChangeCallback (
                                          ABAddressBookRef addressBook,
                                          CFDictionaryRef info,
                                          void *context
                                          )
{
    NSLog(@"callback called ");
    [[TDAddressBookAPI sharedInstance] copyAddressBook];
}

- (id) init {
    self = [super init];
    if (self) {
        CFErrorRef * err = NULL;
        self.addressBook = ABAddressBookCreateWithOptions(NULL, err);
        self.contactList = nil;
        [self copyAddressBook];
        ABAddressBookRegisterExternalChangeCallback (self.addressBook,
                                                     MyAddressBookExternalChangeCallback,
                                                     (__bridge void *)(self));
    }
    return self;
}

- (void)copyAddressBook {
    
    __block BOOL accessGranted = NO;
    
    if (ABAddressBookRequestAccessWithCompletion != NULL) { // We are on iOS 6
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(semaphore);
        });
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    else { // We are on iOS 5 or Older
        accessGranted = YES;
        [self addContactsToAddressBook:self.addressBook];
    }
    
    if (accessGranted) {
        [self addContactsToAddressBook:self.addressBook];
    }
}

- (void)addContactsToAddressBook:(ABAddressBookRef)addressBook {
    if (addressBook != nil) {
        
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
        CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(kCFAllocatorDefault,
                                                                   CFArrayGetCount(people),
                                                                   people);
        
        CFArraySortValues(peopleMutable,
                          CFRangeMake(0, CFArrayGetCount(peopleMutable)),
                          (CFComparatorFunction) ABPersonComparePeopleByName,
                          kABPersonSortByFirstName);
        
        // or to sort by the address book's choosen sorting technique
        //
        // CFArraySortValues(peopleMutable,
        //                   CFRangeMake(0, CFArrayGetCount(peopleMutable)),
        //                   (CFComparatorFunction) ABPersonComparePeopleByName,
        //                   (void*) ABPersonGetSortOrdering());
//        for (CFIndex i = 0; i < CFArrayGetCount(peopleMutable); i++)
//        {
//            ABRecordRef record = CFArrayGetValueAtIndex(peopleMutable, i);
//            NSString *firstName = CFBridgingRelease(ABRecordCopyValue(record, kABPersonFirstNameProperty));
//            NSString *lastName = CFBridgingRelease(ABRecordCopyValue(record, kABPersonLastNameProperty));
//            NSLog(@"person = %@, %@", lastName, firstName);
//        }
        
        CFRelease(people);
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < CFArrayGetCount(peopleMutable); i++)
        {
            TDContactInfo *contactInfo = [[TDContactInfo alloc] init];
            
            ABRecordRef contactPerson = CFArrayGetValueAtIndex(peopleMutable, i);
            contactInfo.id = [NSNumber numberWithInteger:ABRecordGetRecordID(contactPerson)];
            contactInfo.firstName = CFBridgingRelease(ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty));
            contactInfo.lastName =  CFBridgingRelease(ABRecordCopyValue(contactPerson, kABPersonLastNameProperty));
            
            if (contactInfo.firstName != nil && contactInfo.lastName != nil){
                contactInfo.fullName = [NSString stringWithFormat:@"%@ %@", contactInfo.firstName, contactInfo.lastName];
            } else if (contactInfo.firstName == nil && contactInfo.lastName != nil) {
                contactInfo.fullName = [NSString stringWithFormat:@"%@", contactInfo.lastName];
                contactInfo.firstName = @"";
            } else if (contactInfo.firstName != nil && contactInfo.lastName == nil) {
                contactInfo.fullName = [NSString stringWithFormat:@"%@", contactInfo.firstName];
                contactInfo.lastName = @"";
            } else {
                // Contact doesn't have first or last name -- not valid
                continue;
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
                UIImage *image =[UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageDataWithFormat(contactPerson, kABPersonImageFormatThumbnail)];

                contactInfo.contactPicture = image;
            }
            
            [tempArray addObject:contactInfo];
        }
        
        self.contactList = [tempArray copy];
    }
    
    
    
}

- (NSArray*)getContactList {
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
