//
//  RMAppDelegate.m
//  RMStoreDemo
//
//  Created by Hermes Pique on 7/30/13.
//  Copyright (c) 2013 Robot Media SL (http://www.robotmedia.net)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RMAppDelegate.h"
#import "RMStoreViewController.h"
#import "RMPurchasesViewController.h"
#import "RMStore.h"
#import "RMStoreAppReceiptVerifier.h"
#import "RMStoreKeychainPersistence.h"

@implementation RMAppDelegate {
    id<RMStoreReceiptVerifier> _receiptVerifier;
    RMStoreKeychainPersistence *_persistence;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self configureStore];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
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
    _receiptVerifier = [[RMStoreAppReceiptVerifier alloc] init];
    [RMStore defaultStore].receiptVerifier = _receiptVerifier;
    
    _persistence = [[RMStoreKeychainPersistence alloc] init];
    [RMStore defaultStore].transactionPersistor = _persistence;
}

@end
