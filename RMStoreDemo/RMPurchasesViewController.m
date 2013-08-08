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

@interface RMPurchasesViewController()<RMStoreObserver>

@end

@implementation RMPurchasesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Purchases", @"");
    
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Restore", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(restoreAction)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashAction)];
    self.navigationItem.rightBarButtonItems = @[item2, item1];
    
    [[RMStore defaultStore] addStoreObserver:self];
}

- (void)dealloc
{
    [[RMStore defaultStore] removeStoreObserver:self];
}

#pragma mark Actions

- (void)restoreAction
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[RMStore defaultStore] restoreTransactionsOnSuccess:^{
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
    [[RMStore defaultStore] clearPurchases];
    [self.tableView reloadData];
}

#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[RMStore defaultStore] purchasedProductIdentifiers].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    RMStore *store = [RMStore defaultStore];
    NSArray *purchasedProducts = [store purchasedProductIdentifiers];
    NSString *productID = [purchasedProducts objectAtIndex:indexPath.row];
    SKProduct *product = [store productForIdentifier:productID];
    cell.textLabel.text = product ? product.localizedTitle : productID;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [store countPurchasesForIdentifier:productID]];
    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RMStore *store = [RMStore defaultStore];
    NSArray *purchasedProducts = [store purchasedProductIdentifiers];
    NSString *productID = [purchasedProducts objectAtIndex:indexPath.row];
    const BOOL consumed = [store consumeProductForIdentifier:productID];
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
    [self.tableView reloadData];    
}

@end
