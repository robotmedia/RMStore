//
//  RMStoreViewController.h
//  RMStore
//
//  Created by Hermes Pique on 7/30/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RMStoreViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *paymentsDisabledLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
