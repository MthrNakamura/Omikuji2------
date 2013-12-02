//
//  LoginViewController.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/11/11.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "LoginViewController.h"
#import "TopViewController.h"
#import "AsyncURLConnection.h"
#import "ContentsUpdateManager.hpp"

#import "AppDelegate.h"
#import "AlertUtil.hpp"

#include <utility>

static AppDelegate *delegate;

// --- ステータス ---
enum STATUS : unsigned {
    STATUS_LOGIN = 0,
    STATUS_LIST,
    STATUS_DOWNLOAD
};

// --- 内部エラータイプ ---
enum ERROR_TYPE : unsigned {
    INVALID_NAME = 0,     // 名前が存在しない
    INVALID_PASSWORD,     // パスワードが存在しない
};

// アラートタイトル
static NSString *const _ALERT_TITLE[] =
{
    @"ログイン", @"コンテンツ", @"ダウンロード"
};

// エラーメッセージ
static NSString *const _ERROR_MSG[] =
{
    @"IDが入力されていません。",
    @"パスワードが入力されていません。"
};

// 成功時ラベル
static NSString *const _LABEL_TEXT_OK[] =
{
    @"コンテンツリストの取得中です",
    @"コンテンツのダウンロード中です",
    @"コンテンツの取得に成功しました"
};

@interface LoginViewController ()

@end

@implementation LoginViewController



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	   
    //AppDelegateを取得
    delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    
    
    // 背景をクリックしたらキーボードを隠す
    UITapGestureRecognizer *rec = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(hideSoftKeyboard)];
    [self.view addGestureRecognizer:rec];
    
    //delegate.networking = NO;
    //delegate.numLoop = 0;
}

// **********************************************
// * ソフトウェアキーボードを隠す処理
// **********************************************
- (void)hideSoftKeyboard {
    [self.userNameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

// **********************************************
// * ビューの表示時コールバック
// **********************************************
- (void)viewDidAppear:(BOOL)animated
{
    // *** ログアウト後はログイン画面を表示したまま ***
    if (delegate.loggedOut) {
        delegate.loggedOut = NO;
        return ;
    }
    
    // *** ログインパラメータの取得 ***
    auto defaults = [NSUserDefaults standardUserDefaults];
    NSString *name = [defaults objectForKey:@"uname"];
    NSString *passwd = [defaults objectForKey:@"passwd"];
    
    // ログインパラメータが不足 -> 終了
    // 不備がある場合は終了
    if ( ![self enableLogin:name passWord:passwd alert:NO] ) return;
    
    // -------------------------------------------
    //  すでにログインパラメータが設定されているとき
    //    -> 自動ログインの実行
    // -------------------------------------------
    
    self.statusLabel.text = @"自動ログインをします。";
        
    // フィールドにユーザー名とパスワードを設定
    self.userNameField.text = name;
    self.passwordField.text = passwd;

    // ログイン処理の実行
    [self login:name passWord:passwd gotoTopPage:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// ***********************************************
// * 画面上部のステータスバーを非表示に
// ***********************************************
- (BOOL)prefersStatusBarHidden { return YES; }

// ===============================================
//
//  ログイン関連処理
//
// ===============================================

// ***********************************************
// * ログインボタンが押された
// ***********************************************
- (IBAction)doLogin:(id)sender {
    
    //ユーザー名とパスワードを取得
    auto name = [self.userNameField text];
    auto password = [self.passwordField text];
    
    // 不備がある場合は終了
    if ( ![self enableLogin:name passWord:password alert:YES] ) return;
    
    //ログインを実行
    [self login:name passWord:password gotoTopPage:YES];
}

// ***********************************************
// * ユーザー名を入力してエンターが押された
// ***********************************************
- (IBAction)finishEnteringUserName:(id)sender {
    
    //パスワード入力欄にフォーカスを当てる
    [self.passwordField becomeFirstResponder];
}

// ***********************************************
// * パスワードが入力されてエンターが押された
// ***********************************************
- (IBAction)finishEnteringPassword:(id)sender {
    
    //キーボードを閉じる
    [self.passwordField resignFirstResponder];
    
    //ユーザー名とパスワードを取得
    auto name = [self.userNameField text];
    auto password = [self.passwordField text];
    
    if ( ![self enableLogin:name passWord:password alert:YES] ) return;
    
    //ログインを実行
    [self login:name passWord:password gotoTopPage:YES];
}

// **********************************************
// * ログインパラメータの確認
// **********************************************
- (BOOL)enableLogin:(NSString *)name passWord:(NSString *)password alert:(BOOL)alert {
    
    [self.userNameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    
    if ( [name length]==0 ) {
        if ( alert ) [self showAlert:INVALID_NAME];
        return NO;
    }
    
    if ( [password length]==0 ) {
        if ( alert ) [self showAlert:INVALID_PASSWORD];
        return NO;
    }
    
    return YES;
}

// **********************************************
// * ログインの実処理
// **********************************************
- (void)login:(NSString *)name passWord:(NSString *)password gotoTopPage:(BOOL)goto_top_page {
    
    // *** プログレスバーの設定 ***
    auto progress = [[MBProgressHUD alloc] initWithView:self.view];
    progress.labelText = @"ログイン中";
    
    [self.view addSubview:progress];
    [progress show:YES];    // プログレスバーの表示
    
    // *** ログインの実行 ***

    __block LoginViewController *_self = self;
    
    // ログインリクエストを送信
    NSData *json = nil;
    {
        // POSTパラメータの生成
        auto param = [NSDictionary dictionaryWithObjectsAndKeys:name, @"userId", password, @"password", nil];
        
        NSError *error = nil;
        json = [NSJSONSerialization dataWithJSONObject:param
                                               options:0
                                                 error:&error];
    }
    auto request = ConnectionUtil::createRequest( LOGIN_API, false, json );
    
    // 通信オブジェクトの生成
    AsyncURLConnection *conn = [[AsyncURLConnection alloc]
                                    initWithRequest:request
                                         timeoutSec:TIMEOUT_INTERVAL
    completeBlock:^(AsyncURLConnection *conn, NSData *data) {
        @autoreleasepool {
            // プログレスバーの非表示
            [progress hide:YES];
            [progress removeFromSuperview];
            
            // データチェック
            ConnectionUtil::HTTP_CODE code;
            auto response = ConnectionUtil::checkAndSerializeResponse( conn.response, data, code );
            
            // レスポンスが存在しなければ終了
            if ( !response ) {
                
                auto atype = AlertUtil::convert( code, true );
                
                AlertUtil::showAlert( _ALERT_TITLE[ STATUS_LOGIN ], atype );
                return;
            }
            
            // ログイン情報の保存
            [_self registLoginInfo:name
                          passWord:password
                          response:response];
            
            // コンテンツの更新
            [self updateContents:goto_top_page];
        }
        
    }
                                progressBlock:nil
    errorBlock:^(AsyncURLConnection *conn, NSError *error) {
        @autoreleasepool {
            // プログレスバーの非表示
            [progress hide:YES];
            [progress removeFromSuperview];
            
            // エラーダイアログの表示
            auto type = ( error.code==NSURLErrorTimedOut ) ? AlertUtil::TIMEDOUT
            : AlertUtil::NETWORK_ERROR;
            AlertUtil::showAlert( _ALERT_TITLE[ STATUS_LOGIN ], type );
            
            // エラーによるリセット処理
            [self resetForError];
        }
        
    }];
    
    // 通信の開始
    [conn performRequest];
}

// ***********************************************
//  ログイン情報の保存
// ***********************************************
- (void)registLoginInfo:(NSString *)name passWord:(NSString *)password response:(NSDictionary *)response
{
    
    //ログイン成功
    //アクセストークンを取得
    delegate.accessToken = [response objectForKey:@"accessToken"];
    //アプリの起動モードを取得
    delegate.singleAppMode = ( [[response objectForKey:@"appMode"] intValue]!=0 );

    //ログイン情報を記憶
    auto defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:name forKey:@"uname"];
    [defaults setObject:password forKey:@"passwd"];
}

// ===============================================
//
//  コンテンツ取得関連処理
//
// ===============================================

// **********************************************
// * コンテンツの取得
// **********************************************
- (void)updateContents:(BOOL)goto_toppage {

    __block LoginViewController* _self = self;
    
    // *** プログレス処理 ***
    auto progress_func = ^(ContentsUpdateManager::STATE state) {

        // 進捗状態の取得
        STATUS stat = ( state==ContentsUpdateManager::COMPLETE_GETLIST ) ? STATUS_LIST
                                                                         : STATUS_DOWNLOAD;

        // 表示するラベルの更新
        _self.statusLabel.text = _LABEL_TEXT_OK[ stat ];
    };
    
    // *** エラーの処理 ***
    auto error_func = ^(AlertUtil::ALERT_TYPE type, ContentsUpdateManager::STATE state) {
        
        // 進捗状態の取得
        STATUS stat = ( state==ContentsUpdateManager::START_GETLIST ) ? STATUS_LIST
                                                                      : STATUS_DOWNLOAD;
        
        // アラートの表示
        AlertUtil::showAlert( _ALERT_TITLE[ stat ], type );
        
        // 認証エラー時はアクセストークンを無効にする
        if ( type==AlertUtil::AUTH_ERROR ) APP_DEL.accessToken = nil;
        
        [_self resetForError];
    };
    
    // コンテンツの更新
    ContentsUpdateManager::update( self, true, progress_func, error_func );
}

// **********************************************
// * エラー時のリセット
// **********************************************
- (void)resetForError {
    self.statusLabel.text = @"ようこそ";
}

// ===============================================
//
//  ユーティリティ処理
//
// ===============================================

// **********************************************
// * アラートダイアログの表示
// **********************************************
- (void)showAlert:(ERROR_TYPE)error_type {
    
    // アラートビューの生成
    auto alert_view = [[UIAlertView alloc] initWithTitle:_ALERT_TITLE[ STATUS_LOGIN ]
                                                 message:_ERROR_MSG[ error_type ]
                                                delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil, nil];
    
    // アラートビューの表示
    [alert_view show];
};


@end
