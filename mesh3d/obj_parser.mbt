///|
/// OBJ 文件解析器
///
/// 解析 Wavefront OBJ 格式，支持以下指令：
/// - `o name` — 定义对象（每个对象对应一个 Mesh）
/// - `v x y z` — 顶点（全局索引，1-based）
/// - `f v0 v1 v2` — 三角面（顶点索引，1-based）
/// - `#` — 注释行（跳过）
/// - `vn`/`vt`/`mtllib`/`usemtl` — 暂不支持，安全跳过
///
/// 解析后每个对象的顶点索引会被转换为局部索引（0-based），
/// 这样每个 Mesh 可以独立渲染。
///
/// # Example
/// ```mbt check
/// test {
///   let obj = "o box\nv 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nf 1 2 3\nf 1 3 4\n"
///   let scene = @mesh3d.parse_obj(obj)
///   assert_eq(scene.mesh_count(), 1)
///   let m = scene.get_mesh(0)
///   assert_eq(m.vertex_count(), 4)
///   assert_eq(m.face_count(), 2)
/// }
/// ```

///|
/// 解析 OBJ 文本，返回 Scene
///
/// 每个 `o` 指令开始一个新的 Mesh。
/// 顶点使用全局索引（OBJ 标准），面索引会被转换为每个 Mesh 的局部索引。
pub fn parse_obj(content : String) -> Scene {
  let scene = new_scene(name="obj_scene")
  let global_vertices : Array[Vertex] = []
  let current_meshes : Array[Mesh] = []
  let mesh_vertex_indices : Array[Array[Int]] = []

  let lines = content.split("\n").to_array()
  for line in lines {
    let trimmed = line.trim()
    if trimmed.length() == 0 {
      continue
    }
    if trimmed.has_prefix("#") {
      continue
    }
    let parts = trimmed.split(" ").to_array()
    if parts.length() == 0 {
      continue
    }
    let cmd = parts[0]
    if cmd.equal_to_string("o") {
      let obj_name = if parts.length() > 1 { parts[1].to_string() } else { "unnamed" }
      current_meshes.push(new_mesh(name=obj_name))
      mesh_vertex_indices.push([])
    } else if cmd.equal_to_string("v") {
      if parts.length() >= 4 {
        let x = parse_double_sv(parts[1])
        let y = parse_double_sv(parts[2])
        let z = parse_double_sv(parts[3])
        global_vertices.push({ x, y, z })
      }
    } else if cmd.equal_to_string("f") {
      if current_meshes.length() > 0 && parts.length() >= 4 {
        let mesh_idx = current_meshes.length() - 1
        let mesh = current_meshes[mesh_idx]
        let v_indices = mesh_vertex_indices[mesh_idx]
        let g0 = parse_face_index_sv(parts[1])
        let g1 = parse_face_index_sv(parts[2])
        let g2 = parse_face_index_sv(parts[3])
        let l0 = local_index(v_indices, g0)
        let l1 = local_index(v_indices, g1)
        let l2 = local_index(v_indices, g2)
        mesh.add_face(l0, l1, l2)
      }
    }
  }

  // 将全局顶点数据填入各 Mesh
  for i in 0..<current_meshes.length() {
    let mesh = current_meshes[i]
    let indices = mesh_vertex_indices[i]
    for gidx in indices {
      if gidx >= 0 && gidx < global_vertices.length() {
        let v = global_vertices[gidx]
        mesh.add_vertex(v.x, v.y, v.z)
      }
    }
    scene.add_mesh(mesh)
  }

  scene
}

///|
/// 解析面的顶点索引（处理 "v/vt/vn" 格式，取 v 部分）
/// OBJ 索引是 1-based，转换为 0-based
fn parse_face_index_sv(token : StringView) -> Int {
  let s = if token.contains("/") {
    let parts = token.split("/").to_array()
    if parts.length() > 0 { parts[0] } else { token }
  } else {
    token
  }
  try {
    @str.parse_int(s) - 1
  } catch {
    _ => 0
  }
}

///|
/// 获取或添加全局顶点索引到局部列表，返回局部索引
fn local_index(
  v_indices : Array[Int],
  global_idx : Int
) -> Int {
  for i in 0..<v_indices.length() {
    if v_indices[i] == global_idx {
      return i
    }
  }
  v_indices.push(global_idx)
  v_indices.length() - 1
}

///|
/// 解析 Double from StringView（容错处理）
fn parse_double_sv(s : StringView) -> Double {
  let trimmed = s.trim()
  try {
    @str.parse_double(trimmed)
  } catch {
    _ => 0.0
  }
}
