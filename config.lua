local M = {
    MARGIN_TOP = 40,
    MENU_MARGIN_LEFT = 5,

    VERTICLE_SEPREATOR_WIDTH = 15,

    DropdownItemHeigh = 20,

    WindowSize = {
        w = 1280,
        h = 600,
    },

    MenuType = {
        Frame = 0,
        B3Tree = 1,
        B3Log = 2,
    }, 

    B3TreeDir = "/res/b3_tree/",
    B3LogDir = "/res/b3_log/",

    -- 开始运行监控时需要开启的服务端地址
    RuntimeServerIp = "*",
    RuntimeServerPort = 28989,

    -- 相同内容frame的最大折叠次数
    FoldSameFrames = nil,
}

M.ScrollerMatrix = {
    x = 80,
    y = M.MARGIN_TOP,
    w = M.WindowSize.w - 60,
    h = M.WindowSize.h,        
}

return M