//
//  ManagementViewController.h
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/11/19.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import <UIKit/UIKit.h>

// ================================================================
//
//  管理者画面ビューコントローラ
//
// ================================================================
@interface ManagementViewController : UITableViewController <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

- (IBAction)finishManagementMenu:(id)sender;

//ログアウト
- (void)logout;

//アップデート
- (void)updateContents;

//ペアリング
- (void)bluetoothPairing;
@end
