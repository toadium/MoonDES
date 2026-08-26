// ===========================================================================
// Grid2D — 2D 网格测试
// ===========================================================================

///|
/// Grid2D：基本读写
test "grid2d basic get set" {
  let g = new_grid2d(width=3, height=3, default="Empty")
  assert_eq(g.width(), 3)
  assert_eq(g.height(), 3)
  assert_eq(g.cell_count(), 9)
  assert_eq(g.get(1, 1), "Empty")
  g.set(1, 1, "Tree")
  assert_eq(g.get(1, 1), "Tree")
  assert_eq(g.get(0, 0), "Empty")
}

///|
/// Grid2D：Moore 邻域
test "grid2d moore neighbors" {
  let g = new_grid2d(width=3, height=3, default="X")
  let nbrs = g.neighbors_moore(1, 1)
  assert_eq(nbrs.length(), 8) // 中心有 8 个邻居
  for n in nbrs {
    assert_eq(n, "X")
  }
}

///|
/// Grid2D：Moore 邻域边界
test "grid2d moore corner" {
  let g = new_grid2d(width=3, height=3, default="X")
  let nbrs = g.neighbors_moore(0, 0) // 左上角
  assert_eq(nbrs.length(), 3) // 只有 3 个邻居
}

///|
/// Grid2D：Von Neumann 邻域
test "grid2d von_neumann neighbors" {
  let g = new_grid2d(width=3, height=3, default="X")
  let nbrs = g.neighbors_von_neumann(1, 1)
  assert_eq(nbrs.length(), 4) // 中心有 4 个邻居
}

///|
/// Grid2D：Von Neumann 邻域边界
test "grid2d von_neumann corner" {
  let g = new_grid2d(width=3, height=3, default="X")
  let nbrs = g.neighbors_von_neumann(0, 0)
  assert_eq(nbrs.length(), 2) // 左上角只有 2 个邻居
}

///|
/// Grid2D：边界检查
test "grid2d in_bounds" {
  let g = new_grid2d(width=3, height=3, default="X")
  assert_true(g.in_bounds(0, 0))
  assert_true(g.in_bounds(2, 2))
  assert_false(g.in_bounds(3, 0))
  assert_false(g.in_bounds(0, 3))
  assert_false(g.in_bounds(-1, 0))
}

///|
/// Grid2D：填充
test "grid2d fill" {
  let g = new_grid2d(width=2, height=2, default="A")
  g.fill("B")
  assert_eq(g.get(0, 0), "B")
  assert_eq(g.get(1, 0), "B")
  assert_eq(g.get(0, 1), "B")
  assert_eq(g.get(1, 1), "B")
}

///|
/// Grid2D：条件计数
test "grid2d count_if" {
  let g = new_grid2d(width=3, height=3, default="Empty")
  g.set(0, 0, "Tree")
  g.set(1, 1, "Tree")
  g.set(2, 2, "Burning")
  assert_eq(g.count_value("Tree"), 2)
  assert_eq(g.count_value("Burning"), 1)
  assert_eq(g.count_value("Empty"), 6)
  assert_eq(g.count_if(fn(v) { v != "Empty" }), 3)
}

///|
/// Grid2D：邻域坐标
test "grid2d neighbor_coords_moore" {
  let g = new_grid2d(width=3, height=3, default="X")
  let coords = g.neighbor_coords_moore(1, 1)
  assert_eq(coords.length(), 8)
  // 检查是否包含 (0,0)
  let mut has_00 = false
  for c in coords {
    if c.0 == 0 && c.1 == 0 {
      has_00 = true
    }
  }
  assert_true(has_00)
}

///|
/// Grid2D：复制
test "grid2d copy" {
  let g = new_grid2d(width=2, height=2, default="A")
  g.set(0, 0, "B")
  let g2 = g.copy()
  assert_eq(g2.get(0, 0), "B")
  // 修改副本不影响原网格
  g2.set(0, 0, "C")
  assert_eq(g.get(0, 0), "B")
  assert_eq(g2.get(0, 0), "C")
}

///|
/// Grid2D：to_string
test "grid2d to_string" {
  let g = new_grid2d(width=2, height=2, default="Tree")
  let s = g.to_string()
  assert_true(s.contains("Grid2D"))
  assert_true(s.contains("2x2"))
}

///|
/// Grid2D：1x1 网格
test "grid2d single cell" {
  let g = new_grid2d(width=1, height=1, default="X")
  assert_eq(g.neighbors_moore(0, 0).length(), 0)
  assert_eq(g.neighbors_von_neumann(0, 0).length(), 0)
}
