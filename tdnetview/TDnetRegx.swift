//
//  TDnetRegx.swift
//  tdnetview
//
//  Created by abars on 2016/03/25.
//  Copyright © 2016年 abars. All rights reserved.
//

import Foundation

struct TDnetRegx{
    var VERSION:Int=0
    var APPENGINE_BASE_URL:String="http://tdnet-search.appspot.com/"
    var TDNET_TOP_URL:String="https://www.release.tdnet.info/inbs/I_main_00.html"
    var TDNET_BASE_URL:String="https://www.release.tdnet.info/inbs/"
    var TDNET_DAY_PAGE_PATTERN:String="frame src=\"(.*)\" name=\"frame_l\""
    var TDNET_NEXT_PAGE_PATTERN:String="location=\'(.*)?\'\" type=\"button\" value=\"次画面\""
    var TDNET_TR_PATTERN:String="<tr>(.*?)</tr>"
    var TDNET_TD_PATTERN:String="<td.*?>(.*?)</td>"
    var TDNET_CONTENT_PATTERN:String="<a href=\"(.*?)\" target=.*>(.*?)</a>"
    var TDNET_ID_N:Int=4
    var TDNET_DATE_ID:Int=0
    var TDNET_COMPANY_CODE_ID:Int=1
    var TDNET_COMPANY_ID:Int=2
    var TDNET_DATA_ID:Int=3
}