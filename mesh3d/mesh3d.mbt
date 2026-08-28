///|
/// 3D 网格数据模型
///
/// 提供 3D 网格的基础数据结构：顶点、面、网格、场景。
/// 配合 obj_parser 解析 OBJ 文件，配合 scene 管理厂区场景。
///
/// 适用于：厂区 3D 平面布置图、构筑物可视化、空间布局仿真。
///
/// # Example
/// ```mbt check
/// test {
///   let v = @mesh3d.new_vertex(1.0, 2.0, 3.0)
///   assert_eq(v.x, 1.0)
///   assert_eq(v.y, 2.0)
///   assert_eq(v.z, 3.0)
///
///   let f = @mesh3d.new_face(0, 1, 2)
///   assert_eq(f.v0, 0)
///   assert_eq(f.v1, 1)
///   assert_eq(f.v2, 2)
/// }
/// ```

///|
/// 3D 顶点
pub(all) struct Vertex {
  x : Double
  y : Double
  z : Double
} derive(Show)

///|
/// 创建顶点
pub fn new_vertex(x : Double, y : Double, z : Double) -> Vertex {
  { x, y, z }
}

///|
/// 三角面（顶点索引，0-based）
pub(all) struct Face {
  v0 : Int
  v1 : Int
  v2 : Int
} derive(Show)

///|
/// 创建面
pub fn new_face(v0 : Int, v1 : Int, v2 : Int) -> Face {
  { v0, v1, v2 }
}

///|
/// 网格（一个构筑物/几何体）
///
/// 一个 Mesh 对应 OBJ 文件中的一个 `o` 对象。
/// vertices 和 faces 使用局部索引（从 0 开始）。
pub(all) struct Mesh {
  name : String
  vertices : Array[Vertex]
  faces : Array[Face]
  mut category : String
  mut color : String
  mut label : String
} derive(Show)

///|
/// 创建空网格
pub fn new_mesh(name~ : String) -> Mesh {
  {
    name,
    vertices: [],
    faces: [],
    category: "unknown",
    color: "#888888",
    label: "",
  }
}

///|
/// 顶点数
pub fn Mesh::vertex_count(self : Mesh) -> Int {
  self.vertices.length()
}

///|
/// 面数
pub fn Mesh::face_count(self : Mesh) -> Int {
  self.faces.length()
}

///|
/// 添加顶点
pub fn Mesh::add_vertex(self : Mesh, x : Double, y : Double, z : Double) -> Unit {
  self.vertices.push({ x, y, z })
}

///|
/// 添加面（0-based 索引）
pub fn Mesh::add_face(self : Mesh, v0 : Int, v1 : Int, v2 : Int) -> Unit {
  self.faces.push({ v0, v1, v2 })
}

///|
/// 设置类别和颜色
pub fn Mesh::set_category(
  self : Mesh,
  category~ : String,
  color~ : String
) -> Unit {
  self.category = category
  self.color = color
}

///|
/// 设置标签
pub fn Mesh::set_label(self : Mesh, label : String) -> Unit {
  self.label = label
}

///|
/// 计算网格的边界框
///
/// 返回 (min_x, min_y, min_z, max_x, max_y, max_z)
pub fn Mesh::bounding_box(self : Mesh) -> (Double, Double, Double, Double, Double, Double) {
  if self.vertices.length() == 0 {
    return (0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
  }
  let mut min_x = self.vertices[0].x
  let mut min_y = self.vertices[0].y
  let mut min_z = self.vertices[0].z
  let mut max_x = self.vertices[0].x
  let mut max_y = self.vertices[0].y
  let mut max_z = self.vertices[0].z
  for v in self.vertices {
    if v.x < min_x {
      min_x = v.x
    }
    if v.y < min_y {
      min_y = v.y
    }
    if v.z < min_z {
      min_z = v.z
    }
    if v.x > max_x {
      max_x = v.x
    }
    if v.y > max_y {
      max_y = v.y
    }
    if v.z > max_z {
      max_z = v.z
    }
  }
  (min_x, min_y, min_z, max_x, max_y, max_z)
}

///|
/// 计算网格中心点
pub fn Mesh::center(self : Mesh) -> (Double, Double, Double) {
  let (min_x, min_y, min_z, max_x, max_y, max_z) = self.bounding_box()
  ((min_x + max_x) / 2.0, (min_y + max_y) / 2.0, (min_z + max_z) / 2.0)
}

///|
/// 3D 场景（整个厂区）
///
/// 包含多个 Mesh 对象，代表整个污水处理厂的 3D 布置。
pub(all) struct Scene {
  name : String
  meshes : Array[Mesh]
} derive(Show)

///|
/// 创建空场景
pub fn new_scene(name~ : String) -> Scene {
  { name, meshes: [] }
}

///|
/// 网格数量
pub fn Scene::mesh_count(self : Scene) -> Int {
  self.meshes.length()
}

///|
/// 添加网格
pub fn Scene::add_mesh(self : Scene, mesh : Mesh) -> Unit {
  self.meshes.push(mesh)
}

///|
/// 获取网格（按索引）
pub fn Scene::get_mesh(self : Scene, index : Int) -> Mesh {
  self.meshes[index]
}

///|
/// 总顶点数
pub fn Scene::total_vertices(self : Scene) -> Int {
  let mut total = 0
  for m in self.meshes {
    total += m.vertex_count()
  }
  total
}

///|
/// 总面数
pub fn Scene::total_faces(self : Scene) -> Int {
  let mut total = 0
  for m in self.meshes {
    total += m.face_count()
  }
  total
}

///|
/// 计算场景边界框
///
/// 返回 (min_x, min_y, min_z, max_x, max_y, max_z)
pub fn Scene::bounding_box(
  self : Scene
) -> (Double, Double, Double, Double, Double, Double) {
  if self.meshes.length() == 0 {
    return (0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
  }
  let mut first = true
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut min_z = 0.0
  let mut max_x = 0.0
  let mut max_y = 0.0
  let mut max_z = 0.0
  for m in self.meshes {
    let (mx, my, mz, mx2, my2, mz2) = m.bounding_box()
    if first {
      min_x = mx
      min_y = my
      min_z = mz
      max_x = mx2
      max_y = my2
      max_z = mz2
      first = false
    } else {
      if mx < min_x {
        min_x = mx
      }
      if my < min_y {
        min_y = my
      }
      if mz < min_z {
        min_z = mz
      }
      if mx2 > max_x {
        max_x = mx2
      }
      if my2 > max_y {
        max_y = my2
      }
      if mz2 > max_z {
        max_z = mz2
      }
    }
  }
  (min_x, min_y, min_z, max_x, max_y, max_z)
}

///|
/// 计算场景中心点
pub fn Scene::center(self : Scene) -> (Double, Double, Double) {
  let (min_x, min_y, min_z, max_x, max_y, max_z) = self.bounding_box()
  ((min_x + max_x) / 2.0, (min_y + max_y) / 2.0, (min_z + max_z) / 2.0)
}
