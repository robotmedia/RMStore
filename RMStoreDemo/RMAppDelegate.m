//
//  RMAppDelegate.m
//  RMStoreDemo
//
//  Created by Hermes Pique on 7/30/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import "RMAppDelegate.h"
#import "RMStoreViewController.h"
#import "RMPurchasesViewController.h"
#import "RMStoreLocalReceiptVerificator.h"

@implementation RMAppDelegate {
    RMStoreLocalReceiptVerificator *_receiptVerificator;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self configureStore];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIViewController *storeVC = [[RMStoreViewController alloc] initWithNibName:@"RMStoreViewController" bundle:nil];
    UINavigationController *vc1 = [[UINavigationController alloc] initWithRootViewController:storeVC];
    
    UIViewController *purchasesVC = [[RMPurchasesViewController alloc] initWithNibName:@"RMPurchasesViewController" bundle:nil];
    UINavigationController *vc2 = [[UINavigationController alloc] initWithRootViewController:purchasesVC];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[vc1, vc2];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)configureStore
{
    // Using local receipt verification. You might want to implement your own server-side verification instead.
    _receiptVerificator = [[RMStoreLocalReceiptVerificator alloc] init];
    [RMStore defaultStore].receiptVerificator = _receiptVerificator;
}

@end
