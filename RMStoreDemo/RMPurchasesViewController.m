//
//  RMPurchasesViewController.m
//  RMStore
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

#import "RMPurchasesViewController.h"
#import "RMStore.h"
#import "RMStoreKeychainPersistence.h"

@interface RMPurchasesViewController()<RMStoreObserver>

@end

@implementation RMPurchasesViewController {
    RMStoreKeychainPersistence *_persistence;
    NSArray *_productIdentifiers;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Purchases", @"");
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Restore", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(restoreAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashAction)];
    
    RMStore *store = [RMStore defaultStore];
    [store addStoreObserver:self];
    _persistence = store.transactionPersistor;
    _productIdentifiers = _persistence.purchasedProductIdentifiers.allObjects;
}

- (void)dealloc
{
    [[RMStore defaultStore] removeStoreObserver:self];
}

#pragma mark Actions

- (void)restoreAction
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[RMStore defaultStore] restoreTransactionsOnSuccess:^(NSArray *transactions) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;        
        [self.tableView reloadData];
    } failure:^(NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Restore Transactions Failed", @"")
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles:nil];
        [alertView show];
    }];
}

- (void)trashAction
{
    [_persistence removeTransactions];
    _productIdentifiers = _persistence.purchasedProductIdentifiers.allObjects;
    [self.tableView reloadData];
}

#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _productIdentifiers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    RMStore *store = [RMStore defaultStore];
    NSString *productID = _productIdentifiers[indexPath.row];
    SKProduct *product = [store productForIdentifier:productID];
    cell.textLabel.text = product ? product.localizedTitle : productID;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)[_persistence countProductOfdentifier:productID]];
    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *productID = _productIdentifiers[indexPath.row];
    const BOOL consumed = [_persistence consumeProductOfIdentifier:productID];
    if (consumed)
    {
        [self.tableView reloadData];
    }
}

#pragma mark RMStoreObserver

- (void)storeProductsRequestFinished:(NSNotification*)notification
{
    [self.tableView reloadData];
}

- (void)storePaymentTransactionFinished:(NSNotification*)notification
{
    _productIdentifiers = _persistence.purchasedProductIdentifiers.allObjects;
    [self.tableView reloadData];
}

@end
