//
//  AlertUtil.h
//  Welcome抽選会
//
//  Created by tadasuke tsumura on 2013/11/27.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//
#pragma once

#include "ConnectionUtils.hpp"

// ----------------------------------------------
//
//  アラート系ユーティル
//
// ----------------------------------------------
namespace AlertUtil {
    
    // --- 特殊アラート種別 ---
    enum ALERT_TYPE : unsigned {
        INVALID_PARAM = 0,  // パラメータ不正.    400
        AUTH_ERROR,         // 認証エラー.       401
        LOGIN_AUTH_ERROR,   // ログイン認証エラー  401
        STATUS_ERROR,       // 状態エラー.       403
        CONTENT_ERROR,      // コンテンツ無し.    404
        SERVER_ERROR,       // サーバエラー.      500
        TIMEDOUT,           // タイムアウト
        NETWORK_ERROR,      // ネットワークエラー
        ALERT_NONE,         // アラートなし
    };
    
    // YES/NOアラートのボタンID
    enum BUTTON_ID : unsigned {
        CANCEL_BUTTON = 0,
        YES_BUTTON = 1
    };
    
    // ******************************************
    // * アラート表示
    // ******************************************
    void showAlert(NSString *title, NSString *msg);
    
    // ******************************************
    // * アラート表示
    // ******************************************
    void showAlert(NSString *title, ALERT_TYPE type);
    
    // ******************************************
    // * アラート表示
    // ******************************************
    void showAlert(NSString *title, ConnectionUtil::HTTP_CODE code, bool login=false);
    
    // ******************************************
    // * YES/NOアラートの表示
    // ******************************************
    template <typename T>
    void showYesNoAlert(NSString *title, NSString *msg, T *delegate, int tag);
    
    // ******************************************
    // * アラート用特殊メッセージの取得
    // ******************************************
    NSString *const getMsg(ALERT_TYPE type);
    
    // ******************************************
    // * アラートタイプとHTTPレスポンスコードの変換
    // ******************************************
    ALERT_TYPE convert(ConnectionUtil::HTTP_CODE code, bool login_stage);
}

// ******************************************
// * YES/NOアラートの表示
// ******************************************
template <typename T>
void AlertUtil::showYesNoAlert(NSString *title, NSString *msg, T *delegate, int tag) {
    auto alert = [[UIAlertView alloc] initWithTitle:title
                                            message:msg
                                           delegate:delegate
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"Yes", nil];
    alert.tag = tag;
    [alert show];
}


