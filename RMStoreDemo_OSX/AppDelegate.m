//
//  AppDelegate.m
//  RMStoreDemo_OSX
//
//  Created by Sergey P on 12.07.16.
//  Copyright © 2016 Robot Media. All rights reserved.
//

#import "AppDelegate.h"
#import "RMStore.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application

    NSSet *products = [NSSet setWithArray:@[@"fabulousIdol", @"rootBeer", @"rubberChicken"]];
    [[RMStore defaultStore] requestProducts:products success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
        NSLog(@"Products loaded");
    } failure:^(NSError *error) {
        NSLog(@"Something went wrong");
    }];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
