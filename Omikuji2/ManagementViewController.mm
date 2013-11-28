//
//  ManagementViewController.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/11/19.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "ManagementViewController.h"
#import "LoginViewController.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "AsyncURLConnection.h"
#import "TopViewController.h"

#import "AppDelegate.h"
#import "MBProgressHUD.h"

#import "AlertUtil.hpp"
#import "ContentsUpdateManager.hpp"

// --- ダイアログタグ ---
enum DIALOG_TAG : int {
    TAG_UPDATE = 100,   // 更新
    TAG_LOGOUT,         // ログアウト
    TAG_PRINTER         // プリンタ設定
};

// --- セルインデックス ---
enum CELL_INDEX : unsigned {
    CELL_UPDATE = 0,    // コンテンツ更新
    CELL_LOGOUT,        // ログアウト
    CELL_PRINTER,       // プリンタ設定
    CELL_VERSIONINFO,   // バージョン情報
    CELL_OSS,           // オープンソースライセンス
};

static AppDelegate *delegate;

@interface ManagementViewController ()

@end

@implementation ManagementViewController
//@synthesize updateAlert, logoutAlert, configureAlert;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {return YES;}

// *********************************************
// * セル選択時コールバック
// *********************************************
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    // メニュー番号
    switch ( indexPath.row ) {
            
        // コンテンツ更新
        case CELL_UPDATE :
            [self eventUpdateContents];
            break;
            
        // ログアウト
        case CELL_LOGOUT :
            [self eventLogout];
            break;
            
        // プリンタ設定
        case CELL_PRINTER :
            [self eventConfigurePrinter];
            break;
            
        // バージョン情報
        case CELL_VERSIONINFO :
            [self eventVersionInfo];
            break;
            
        // それ以外は何もしない
        default:
            break;
    }
    
    // ハイライトの解除
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// *********************************************
// * 閉じるボタンの押下時
// *********************************************
- (IBAction)finishManagementMenu:(id)sender {
    TopViewController *topView = [self.storyboard instantiateViewControllerWithIdentifier:@"TopView"];
    [self presentViewController:topView animated:YES completion:nil];
    //[self dismissViewControllerAnimated:YES completion:nil];
}

// *********************************************
// * コンテンツ更新セルの押下時
// *********************************************
- (void)eventUpdateContents {
    
    // Yes/Noアラートの表示
    AlertUtil::showYesNoAlert( @"コンテンツの更新",
                               @"コンテンツを更新しますか",
                               self,
                               TAG_UPDATE );
}

// *********************************************
// * ログアウトセルの押下時
// *********************************************
- (void)eventLogout {
    
    // Yes/Noアラートの表示
    AlertUtil::showYesNoAlert( @"ログアウト",
                               @"ログアウトしますか",
                               self,
                               TAG_LOGOUT );
}

// *********************************************
// * プリンタ設定セルの押下時
// *********************************************
- (void)eventConfigurePrinter {
    
    // Yes/Noアラートの表示
    AlertUtil::showYesNoAlert( @"プリンタ設定",
                               @"プリンタに接続します",
                               self,
                               TAG_PRINTER );
}

// *********************************************
// * バージョン表示セルの押下時
// *********************************************
- (void)eventVersionInfo {
    
    // アラートの表示
    AlertUtil::showAlert( @"バージョン情報", VERSION_INFO );
}

// *********************************************
// * アラートビューイベントコールバック
// *********************************************
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Cancelボタンがおされたときは終了
    if ( buttonIndex==AlertUtil::CANCEL_BUTTON ) return;
    
    // タグごとの処理
    switch ( alertView.tag ) {
            
            // アップデートの実行
        case TAG_UPDATE :
            [self updateContents];
            break;
            
            // ログアウトの実行
        case TAG_LOGOUT :
            [self logout];
            break;
            
            // プリンタ設定の実行
        case TAG_PRINTER :
            [self bluetoothPairing];
            break;
            
        default :
            break;
    }
}

// ---------------------------------------------
//
//  ログアウト処理関連
//
// ---------------------------------------------

// *********************************************
// * ログアウト処理
// *********************************************
- (void)logout {

    // プログレスバーの表示
    MBProgressHUD *progress = [[MBProgressHUD alloc] initWithView:self.view];
    progress.labelText = @"ログアウト中";
    [self.view addSubview:progress];
    [progress show:YES];

    // 通信オブジェクトの生成
    auto request = ConnectionUtil::createRequest( LOGOUT_API, true, nil );
    AsyncURLConnection *conn = [[AsyncURLConnection alloc] initWithRequest:request
                                                                timeoutSec:TIMEOUT_INTERVAL
    // 完了時処理
    completeBlock:^(AsyncURLConnection *conn, NSData *data) {
        
        // レスポンスコードに応じたダイアログ表示
        switch (conn.response.statusCode) {
            case 400:
                AlertUtil::showAlert( @"ログアウト", AlertUtil::INVALID_PARAM );
                break;
            case 500:
                AlertUtil::showAlert( @"ログアウト", AlertUtil::SERVER_ERROR );
                break;
            default:
                break;
        }
        
        [progress hide:YES];
        [progress removeFromSuperview];
        
    }
    progressBlock:nil
                                
    // エラー時処理
    errorBlock:^(AsyncURLConnection *conn, NSError *error) {
        [progress hide:YES];
        [progress removeFromSuperview];
        
    }];

    // 通信の同期実行
    [conn performRequest];
    [conn join];
    
    // ログインページへの遷移
    [self goToLoginPage];
}

// ---------------------------------------------
//
//  プリンタ設定関連
//
// ---------------------------------------------

// *********************************************
// * Bluetoothのペアリング処理
// *********************************************
- (void)bluetoothPairing
{
    // Bluetoothに対応しているか判定する
    if ( UIDevice.currentDevice.systemVersion.floatValue<6.0 ) {
        
        // 未対応の場合は終了
        AlertUtil::showAlert( @"Bluetooth未対応", @"この処理はiOS6以降のみご利用できます" );
        return;
    }
    
    // Bluetooth設定画面の表示
    [[EAAccessoryManager sharedAccessoryManager]
                showBluetoothAccessoryPickerWithNameFilter:nil
                                                completion:nil];
}

// ---------------------------------------------
//
//  コンテンツ更新関連
//
// ---------------------------------------------

- (void)updateContents {
    
    __block ManagementViewController *_self = self;
    
    // *** エラーの処理 ***
    auto error_func = ^(AlertUtil::ALERT_TYPE type, ContentsUpdateManager::STATE state) {
        
        // アラートの表示
        AlertUtil::showAlert( @"コンテンツ更新", type );
        
        // 認証エラー時はアクセストークンを無効にする
        if ( type==AlertUtil::AUTH_ERROR ) {
            APP_DEL.accessToken = nil;
            
            [_self goToLoginPage];
        }
    };
    
    // コンテンツの更新
    ContentsUpdateManager::update( self, false, NULL, error_func );
}

// *********************************************
// * ログイン画面への遷移
// *********************************************
- (void)goToLoginPage {
    
    //アクセストークンを破棄する
    delegate.loggedOut = YES;
    delegate.accessToken = nil;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:@"uname"];
    [defaults setObject:nil forKey:@"passwd"];
    
    
    //ログイン画面に遷移
    LoginViewController *loginView = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
    [self presentViewController:loginView animated:YES completion:nil];
}

@end
