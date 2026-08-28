///|
/// mesh3d 单元测试

///|
test "vertex creation" {
  let v = new_vertex(1.0, 2.0, 3.0)
  assert_eq(v.x, 1.0)
  assert_eq(v.y, 2.0)
  assert_eq(v.z, 3.0)
}

///|
test "face creation" {
  let f = new_face(0, 1, 2)
  assert_eq(f.v0, 0)
  assert_eq(f.v1, 1)
  assert_eq(f.v2, 2)
}

///|
test "mesh basic operations" {
  let m = new_mesh(name="test_box")
  assert_eq(m.vertex_count(), 0)
  assert_eq(m.face_count(), 0)

  m.add_vertex(0.0, 0.0, 0.0)
  m.add_vertex(1.0, 0.0, 0.0)
  m.add_vertex(1.0, 1.0, 0.0)
  m.add_vertex(0.0, 1.0, 0.0)
  assert_eq(m.vertex_count(), 4)

  m.add_face(0, 1, 2)
  m.add_face(0, 2, 3)
  assert_eq(m.face_count(), 2)
}

///|
test "mesh bounding box" {
  let m = new_mesh(name="box")
  m.add_vertex(-1.0, -2.0, -3.0)
  m.add_vertex(1.0, 2.0, 3.0)
  m.add_vertex(0.0, 0.0, 0.0)
  let (min_x, min_y, min_z, max_x, max_y, max_z) = m.bounding_box()
  assert_eq(min_x, -1.0)
  assert_eq(min_y, -2.0)
  assert_eq(min_z, -3.0)
  assert_eq(max_x, 1.0)
  assert_eq(max_y, 2.0)
  assert_eq(max_z, 3.0)
}

///|
test "mesh center" {
  let m = new_mesh(name="box")
  m.add_vertex(-2.0, -4.0, -6.0)
  m.add_vertex(2.0, 4.0, 6.0)
  let (cx, cy, cz) = m.center()
  assert_eq(cx, 0.0)
  assert_eq(cy, 0.0)
  assert_eq(cz, 0.0)
}

///|
test "mesh set category" {
  let m = new_mesh(name="test")
  m.set_category(category="一级处理", color="#00a8ff")
  assert_eq(m.category, "一级处理")
  assert_eq(m.color, "#00a8ff")
}

///|
test "scene basic operations" {
  let s = new_scene(name="test_scene")
  assert_eq(s.mesh_count(), 0)

  let m1 = new_mesh(name="mesh1")
  m1.add_vertex(0.0, 0.0, 0.0)
  let m2 = new_mesh(name="mesh2")
  m2.add_vertex(1.0, 1.0, 1.0)

  s.add_mesh(m1)
  s.add_mesh(m2)
  assert_eq(s.mesh_count(), 2)
  assert_eq(s.total_vertices(), 2)
}

///|
test "obj parser - single object" {
  let obj = "o box\nv 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nf 1 2 3\nf 1 3 4\n"
  let scene = parse_obj(obj)
  assert_eq(scene.mesh_count(), 1)
  let m = scene.get_mesh(0)
  assert_eq(m.vertex_count(), 4)
  assert_eq(m.face_count(), 2)
}

///|
test "obj parser - two objects" {
  let obj = "o box1\nv 0 0 0\nv 1 0 0\nv 1 1 0\nf 1 2 3\no box2\nv 2 0 0\nv 3 0 0\nv 3 1 0\nf 4 5 6\n"
  let scene = parse_obj(obj)
  assert_eq(scene.mesh_count(), 2)
  let m1 = scene.get_mesh(0)
  let m2 = scene.get_mesh(1)
  assert_eq(m1.vertex_count(), 3)
  assert_eq(m1.face_count(), 1)
  assert_eq(m2.vertex_count(), 3)
  assert_eq(m2.face_count(), 1)
}

///|
test "obj parser - comments and empty lines" {
  let obj = "# comment\n\no box\nv 0 0 0\nv 1 0 0\nv 1 1 0\nf 1 2 3\n"
  let scene = parse_obj(obj)
  assert_eq(scene.mesh_count(), 1)
  assert_eq(scene.get_mesh(0).vertex_count(), 3)
}

///|
test "obj parser - face with vt/vn format" {
  // f v/vt/vn format - should extract just the vertex index
  let obj = "o box\nv 0 0 0\nv 1 0 0\nv 1 1 0\nf 1/1/1 2/2/1 3/3/1\n"
  let scene = parse_obj(obj)
  assert_eq(scene.mesh_count(), 1)
  let m = scene.get_mesh(0)
  assert_eq(m.vertex_count(), 3)
  assert_eq(m.face_count(), 1)
}

///|
test "category color lookup" {
  assert_eq(category_color("一级处理"), "#00a8ff")
  assert_eq(category_color("二级处理"), "#00cc6a")
  assert_eq(category_color("三级处理"), "#00d4ff")
  assert_eq(category_color("污泥处理"), "#b45309")
  assert_eq(category_color("辅助建筑"), "#9b59b6")
  assert_eq(category_color("厂区设施"), "#6b7280")
  assert_eq(category_color("unknown"), "#888888")
}

///|
test "scene apply plant labels" {
  let obj = "o g0\nv 0 0 0\nv 1 0 0\nv 1 1 0\nf 1 2 3\no g1\nv 2 0 0\nv 3 0 0\nv 3 1 0\nf 4 5 6\n"
  let scene = parse_obj(obj)
  scene.apply_plant_labels()
  let m0 = scene.get_mesh(0)
  let m1 = scene.get_mesh(1)
  // geometry_0 -> 进水检查井 (一级处理)
  assert_eq(m0.label, "进水检查井")
  assert_eq(m0.category, "一级处理")
  assert_eq(m0.color, "#00a8ff")
  // geometry_1 -> 粗格栅间 (一级处理)
  assert_eq(m1.label, "粗格栅间")
  assert_eq(m1.category, "一级处理")
}

///|
test "scene to json string" {
  let obj = "o g0\nv 0 0 0\nv 1 0 0\nv 1 1 0\nf 1 2 3\n"
  let scene = parse_obj(obj)
  scene.apply_plant_labels()
  let json = scene.to_json_string()
  // JSON should contain key fields
  assert_true(json.contains("meshCount"))
  assert_true(json.contains("totalVertices"))
  assert_true(json.contains("totalFaces"))
  assert_true(json.contains("categories"))
  assert_true(json.contains("meshes"))
  assert_true(json.contains("进水检查井"))
  assert_true(json.contains("#00a8ff"))
}
