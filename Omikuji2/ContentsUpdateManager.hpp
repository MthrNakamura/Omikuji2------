//
//  ContentsUpdateManager.h
//  Welcome抽選会
//
//  Created by tadasuke tsumura on 2013/11/27.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#pragma once

#include "AlertUtil.hpp"
#include <functional>

#define APP_DEL ( (AppDelegate *)[[UIApplication sharedApplication] delegate] )

// ===============================================
//
//  コンテンツ更新マネージャ
//
// ===============================================
namespace ContentsUpdateManager {
    
    // *** 進捗状態 ***
    enum STATE : unsigned {
        START_GETLIST = 0,  // コンテンツリスト取得開始
        COMPLETE_GETLIST,   // コンテンツリストの取得完了
        COMPLETE_UPDATE     // アップデートの完了
    };
    
    // --- コンテンツのアップデート ---
    void update(UIViewController *vc,
                bool goto_toppage,
                std::function<void(ContentsUpdateManager::STATE)> progress_func,
                std::function<void(AlertUtil::ALERT_TYPE, ContentsUpdateManager::STATE)> error_func);
    
    // ---  ---
}