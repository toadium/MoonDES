///|
/// 场景管理
///
/// 为污水处理厂场景提供类别配色、标注、JSON 导出功能。
///
/// 6 类构筑物配色方案（与设计文件一致）：
/// - 一级处理：蓝色 #00a8ff
/// - 二级处理：绿色 #00cc6a
/// - 三级处理：青色 #00d4ff
/// - 污泥处理：棕色 #b45309
/// - 辅助建筑：紫色 #9b59b6
/// - 厂区设施：灰色 #6b7280

///|
/// 构筑物类别配色表
let category_colors : Array[(String, String)] = [
  ("一级处理", "#00a8ff"),
  ("二级处理", "#00cc6a"),
  ("三级处理", "#00d4ff"),
  ("污泥处理", "#b45309"),
  ("辅助建筑", "#9b59b6"),
  ("厂区设施", "#6b7280"),
]

///|
/// 污水处理厂 40 个构筑物的类别映射
///
/// 按设计文件的 6 大类划分，索引对应 OBJ 文件中的 geometry_0 ~ geometry_39。
/// 每个条目为 (构筑物名称, 类别)。
let structure_labels : Array[(String, String)] = [
  // 一级处理 (0-5)
  ("进水检查井", "一级处理"),
  ("粗格栅间", "一级处理"),
  ("细格栅间", "一级处理"),
  ("提升泵房", "一级处理"),
  ("曝气沉砂池", "一级处理"),
  ("初沉池", "一级处理"),
  // 二级处理 (6-12)
  ("缺氧池", "二级处理"),
  ("厌氧池", "二级处理"),
  ("好氧池", "二级处理"),
  ("接触区", "二级处理"),
  ("二沉池", "二级处理"),
  ("曝气器", "二级处理"),
  ("搅拌机", "二级处理"),
  // 三级处理 (13-16)
  ("深床滤池", "三级处理"),
  ("紫外消毒渠", "三级处理"),
  ("清水池", "三级处理"),
  ("出水计量槽", "三级处理"),
  // 污泥处理 (17-20)
  ("污泥浓缩池", "污泥处理"),
  ("污泥储池", "污泥处理"),
  ("脱水机房", "污泥处理"),
  ("污泥干化间", "污泥处理"),
  // 辅助建筑 (21-27)
  ("鼓风机房", "辅助建筑"),
  ("加药间", "辅助建筑"),
  ("配电间", "辅助建筑"),
  ("实验室", "辅助建筑"),
  ("办公楼", "辅助建筑"),
  ("维修车间", "辅助建筑"),
  ("仓库", "辅助建筑"),
  // 厂区设施 (28-39)
  ("场地地基", "厂区设施"),
  ("主干道", "厂区设施"),
  ("次干道", "厂区设施"),
  ("管道节点A", "厂区设施"),
  ("管道节点B", "厂区设施"),
  ("管道节点C", "厂区设施"),
  ("出水渠道", "厂区设施"),
  ("闸门", "厂区设施"),
  ("厂区围墙", "厂区设施"),
  ("绿化带", "厂区设施"),
  ("停车场", "厂区设施"),
  ("门卫室", "厂区设施"),
]

///|
/// 获取类别对应的颜色
pub fn category_color(category : String) -> String {
  for pair in category_colors {
    if pair.0 == category {
      return pair.1
    }
  }
  "#888888"
}

///|
/// 为场景中的所有网格设置类别和颜色
///
/// 根据 structure_labels 映射表，按索引为每个 Mesh 设置名称、类别和颜色。
/// 如果 Mesh 数量超过映射表长度，多余的部分标记为 "厂区设施"。
pub fn Scene::apply_plant_labels(self : Scene) -> Unit {
  for i in 0..<self.meshes.length() {
    let mesh = self.meshes[i]
    if i < structure_labels.length() {
      let (label, category) = structure_labels[i]
      mesh.set_label(label)
      mesh.set_category(category~, color=category_color(category))
    } else {
      mesh.set_label("未知构筑物")
      mesh.set_category(category="厂区设施", color=category_color("厂区设施"))
    }
  }
}

///|
/// 导出场景为前端可用的 JSON 字符串
///
/// JSON 格式：
/// ```json
/// {
///   "name": "sewage_plant_3d",
///   "meshCount": 40,
///   "totalVertices": 842,
///   "totalFaces": 1524,
///   "center": [0.0, 0.0, 0.0],
///   "bbox": [min_x, min_y, min_z, max_x, max_y, max_z],
///   "categories": [
///     {"name": "一级处理", "color": "#00a8ff"},
///     ...
///   ],
///   "meshes": [
///     {
///       "name": "geometry_0",
///       "label": "进水检查井",
///       "category": "一级处理",
///       "color": "#00a8ff",
///       "vertices": [[x,y,z], ...],
///       "faces": [[v0,v1,v2], ...]
///     },
///     ...
///   ]
/// }
/// ```
pub fn Scene::to_json_string(self : Scene) -> String {
  let (cx, cy, cz) = self.center()
  let (min_x, min_y, min_z, max_x, max_y, max_z) = self.bounding_box()

  // 类别列表
  let cat_items : Array[String] = []
  for pair in category_colors {
    let cn = pair.0.to_json().stringify()
    let cc = pair.1.to_json().stringify()
    cat_items.push("{\"name\":\{cn},\"color\":\{cc}}")
  }

  // 网格列表
  let mesh_items : Array[String] = []
  for mesh in self.meshes {
    let mn = mesh.name.to_json().stringify()
    let ml = mesh.label.to_json().stringify()
    let mc = mesh.category.to_json().stringify()
    let mcol = mesh.color.to_json().stringify()

    // 顶点数组
    let vert_items : Array[String] = []
    for v in mesh.vertices {
      vert_items.push("[\{v.x},\{v.y},\{v.z}]")
    }

    // 面数组
    let face_items : Array[String] = []
    for f in mesh.faces {
      face_items.push("[\{f.v0},\{f.v1},\{f.v2}]")
    }

    mesh_items.push("{\"name\":\{mn},\"label\":\{ml},\"category\":\{mc},\"color\":\{mcol},\"vertices\":[\{vert_items.join(",")}],\"faces\":[\{face_items.join(",")}]}")
  }

  let sn = self.name.to_json().stringify()
  "{\"name\":\{sn},\"meshCount\":\{self.mesh_count()},\"totalVertices\":\{self.total_vertices()},\"totalFaces\":\{self.total_faces()},\"center\":[\{cx},\{cy},\{cz}],\"bbox\":[\{min_x},\{min_y},\{min_z},\{max_x},\{max_y},\{max_z}],\"categories\":[\{cat_items.join(",")}],\"meshes\":[\{mesh_items.join(",")}]}"
}
