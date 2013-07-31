//
//  RMPurchasesViewController.m
//  RMStore
//
//  Created by Hermes Pique on 7/30/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import "RMPurchasesViewController.h"
#import "RMStore.h"

@implementation RMPurchasesViewController {
    NSArray *_productIdentifiers;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Purchases", @"");
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Restore", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(restoreAction)];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)viewWillAppear:(BOOL)animated
{
    _productIdentifiers = [[RMStore defaultStore] purchasedIdentifiers];
    [self.tableView reloadData];
}

#pragma mark - Actions

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

#pragma mark - Table view data source

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
    NSString *productID = [_productIdentifiers objectAtIndex:indexPath.row];
    SKProduct *product = [store productForIdentifier:productID];
    cell.textLabel.text = product ? product.localizedTitle : productID;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [store countPurchasesForIdentifier:productID]];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *productID = [_productIdentifiers objectAtIndex:indexPath.row];
    const BOOL consumed = [[RMStore defaultStore] consumeProductForIdentifier:productID];
    if (consumed)
    {
        [self.tableView reloadData];
    }
}

@end
