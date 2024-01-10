# 基于love2的行为树追踪工具（windows版本）

## 概述
根据行为树配置文件绘制行为树，再根据运行数据对节点的运行结果绘制不同的颜色，如下图所示：
* 节点 Fail 失败，绘制红色
* 节点 Success 成功，绘制绿色
* 节点 running，绘制换色
* 节点没有被执行到，绘制白色
![](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/B3%20Tracker%20preview.jpg)


---
* 行为树配置采用json文件， 由 [【行为树编辑器 behavior3editor】](https://github.com/wilsonloo/behavior3editor.git) 进行配置生成

* 行为树运行数据采用json文件， 格式需要满足：
```json
{
    "tree_name": 行为树名称,
    "frames": [
        { # 一帧格式
            "frame_id": 帧数,
            "list": [
                [节点id, 状态编码, 提示消息],
                ...
            ],
            "md5": 运行时监控模式需要使用到
        },
        ...
    ]
}
```
如果采用skynet，则可以参考 https://github.com/wilsonloo/behavior3logger.git 输出frame信息

## tracker 提供两种工作模式
* 离线模式：先由目标程序运行行为树运行一段时间， 产生运行结果文件，再启动tracker加载结果文件，展示行为树在每帧的运行状态

* 运行时模式：tracker 开启tcp socket-server，目标程序创建tcp 连接到tracker，目标程序在每一帧结束时将收集到的 数据（需要符合上述的一帧格式）上报给tracker，tracker试试绘制帧的运行状态

## 如何构建
* 第一步：tracker 使用love2d图形引擎，项目已经提供了love2d程序，详见love2d目录；如果love2d有问题或有所缺失，请从官方现在并解压到love2d，建议解压结构如下图:
![love2d结构图](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/love2d_struct.jpg)

第二步：需要包含模块loui:
```sh 
    git submodule update --init --recursive
```

## 如何使用
* 离线模式，参考 `load_file.bat`
    ```bat
        cd love2d

        @rem love ..\\. file <行为树定义文件所在完整目录> <行为树运行日志文件所在完整目录> [--console选项表示开启终端]
        set b3_tree_dir=D:/workstation/behavior3tracker/res/b3_tree/
        set b3_log_dir=D:/workstation/behavior3tracker/res/b3_log/

        love ..\\. file %b3_tree_dir% %b3_log_dir% --console

        cd ..
    ```
    离线模式的工具链示意图：
![](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/load_file_mod.jpg)        

* 运行时模式：参考 `watch_runtime.bat`
    ```bat
        cd love2d

        @rem love ..\\. runtime  <行为树定义文件所在完整目录>  [--console选项表示开启终端]
        set b3_tree_dir=D:/workstation/behavior3tracker/sample/b3_tree/
        love ..\\. runtime %b3_tree_dir% --console

        cd ..
    ```
    运行时模式的工具链示意图:
    ![](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/watch_runtime_mod.jpg)

## 工具具体使用说明
* 面板分为4个区域：
    * 第1区：行为树菜单，展示当前所选择的行为树配置文件名
    * 第2区：离线数据菜单，展示当前的离线运行数据文件名，仅在 离线模式下有效
    * 第3区：子列表
        * 当聚焦于第1区时，显示所有的行为树配置列表
        * 当聚焦于第2区时，显示所有的离线运行数据文件列表
        * 当聚焦于第4区时，显示所有帧列表
    * 第4区：展示行为树当前帧的状态
通过【左、右方向键】可以在【行为树菜单】和 【离线数据菜单】之间进行操作切换

* 选中行为树菜单时，在第3区域显示所有行为树，并将当前的行为树名称会标记为绿色；通过【上、下方向键】选择所需的行为树，然后按回车键确定选择；对于离线模式，确认了行为树后，第2区域会自动刷新对应的离线数据文件列表，并在第4区域重绘最新行为树运行状态：
![](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/menu_tree.jpg)

* 选中离线数据菜单时（只对离线模式有效），在第3区域显示所有离线数据列表，并将当前的文件名标记为绿色；通过【上、下方向键】选择所需的 离线文件名，然后按回车键确定选择；并在第4区重绘最新的行为树运行状态：
![](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/menu-log.jpg)

* 其他情况，第3区域显示行为树帧列表，通过【上、下方向键】选择帧，按【home键】选择最新帧，按【end键】选择最旧帧，按【pageup键】【pagedown键】进行分页切换：
![](https://wilsonloo.oss-cn-guangzhou.aliyuncs.com/img/menu-frames.jpg)

## 其他
* 连续多帧可能出现相同的运行结果，在运行时模式时，可以让主体程序不要继续相同内容帧，同时又为了出现死机的假象，可以在相同内容出现 一定次数后再 上传到tracker
* 在tracker的 config.lua 配置文件里，提供了 FoldSameFrames 配置：
    ```lua
        -- 相同内容frame的最大折叠次数
        FoldSameFrames = nil
    ```
    * FoldSameFrames = nil 表示只要收到 新frame就绘制
    * FoldSameFrames > 0 也表示连续收到相同内容一定次数后才显示，否则忽略；
        通过将 FoldSameFrame = math.maxinteger 可以达到只有不同内容时才显示，如此可以避免 太多帧数据
* 为了实现相同帧内容的检测，需要在主体程序对帧内容做md5，并加入frame数据里
* 对于运行时模式，为了简单，上报的帧是以 ^^^ 作为帧开头，$$$ 作为帧结尾的

## todo 和 缺陷
* 当行为树结构很大时，会超出绘制区域，需要完善滚动条的功能
* 运行时模式 不区分任何单位的frame数据

## 参考
* 行为树编辑工具：https://github.com/wilsonloo/behavior3editor.git
* 行为树运行框架：https://github.com/wilsonloo/behavior3lua.git
* 行为树日志输出工具：https://github.com/wilsonloo/behavior3logger.git