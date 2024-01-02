# 基于love2的行为树追踪工具
* 行为树配置采用json文件， 由beharior3editor 配置生成
* 行为树运行数据采用json文件， 格式需要符合 b3_logger 项目规范

# 设计说明
* 先加载行为树，再根据运行数据逐帧绘制 状态颜色

## 如何构建
第一步：需要包含模块loui:
```sh 
    git submodule update --init --recursive
```

第二步骤：下载love2d 引擎，并解压到项目的love2d目录

## 如何使用，分两种使用模式
* 模式一：加载日志文件
    ```bat
        cd love2d

        @rem love ..\\. file <行为树定义文件> <行为树运行日志文件> [--console选项表示开启终端]
        set b3_file=..\\sample\\close_combat.json
        set b3_log=..\\sample\\b3log-1036200.json
        love ..\\. file %b3_file% %b3_log% --console

        cd ..
    ```

* 模式二：动态读取（待续，todo）

edit the flowing .bat file and change file using res/logic_test.log
load_file.bat load local log file to parse and render
watch_file.bat watch file change、parse and render