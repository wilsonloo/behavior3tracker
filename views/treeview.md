* 创建treeview 根节点：`new_treeview(x, y, w, h)`
* 给指定节点添加孩子节点: `add_child(node, child_id, value, tag, tag_msg)`
* 绘制行为树：`draw(node, re_render，frame)`
    * node 一般是树根
    * re_render: boolean 是否重新绘制
    * frame: 帧（即一棵树的运行新），格式： 各个节点的状态，不同状态将绘制不用颜色连接到各自父节点, 格式：
        ```lua
        frame = {
            frame_id: 序号ID,
            node_value_map = {
                [节点id] = {
                    [1] = 节点状态,
                    [2] = 提示消息，
                    ...
                },
                ...
            }
        }
        ```
* 设置value的meta 列表， 用于定义不同value的颜色等其他信息，例如行为树的节点失败使用红色连线和文本：
```lua
---@param metas: ValueMetaInterface[]
set_value_metas(treeview, metas)
```