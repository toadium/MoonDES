// ===========================================================================
// CellularAutomaton — 元胞自动机测试
// ===========================================================================

///|
/// CA：基本演化
test "ca basic step" {
  let g = @grid2d.new_grid2d(width=3, height=3, default="A")
  let ca = new_ca(grid=g, rule=fn(_grid, _x, _y) { "B" })
  assert_eq(ca.generation_count(), 0)
  ca.step()
  assert_eq(ca.generation_count(), 1)
  assert_eq(ca.count_value("B"), 9)
  assert_eq(ca.count_value("A"), 0)
}

///|
/// CA：多步演化
test "ca evolve" {
  let counter : Array[Int] = [0]
  let g = @grid2d.new_grid2d(width=2, height=2, default="0")
  let ca = new_ca(grid=g, rule=fn(_grid, _x, _y) {
    counter[0] = counter[0] + 1
    counter[0].to_string()
  })
  ca.evolve(5)
  assert_eq(ca.generation_count(), 5)
  // 每步 4 个细胞，5 步后 counter = 20
  assert_eq(counter[0], 20)
}

///|
/// CA：生命游戏 — 孤立细胞死亡
test "ca game_of_life isolated" {
  let g = @grid2d.new_grid2d(width=5, height=5, default="Dead")
  g.set(2, 2, "Alive")
  let ca = new_ca(grid=g, rule=fn(grid, x, y) {
    let nbrs = grid.neighbors_moore(x, y)
    let alive = nbrs.count_if(fn(v) { v == "Alive" })
    if grid.get(x, y) == "Alive" {
      if alive == 2 || alive == 3 {
        "Alive"
      } else {
        "Dead"
      }
    } else if alive == 3 {
      "Alive"
    } else {
      "Dead"
    }
  })
  ca.step()
  // 孤立细胞无邻居，死亡
  assert_eq(ca.count_value("Alive"), 0)
  assert_eq(ca.count_value("Dead"), 25)
}

///|
/// CA：生命游戏 — 闪烁器（周期 2）
test "ca game_of_life blinker" {
  let g = @grid2d.new_grid2d(width=5, height=5, default="Dead")
  // 水平三连
  g.set(1, 2, "Alive")
  g.set(2, 2, "Alive")
  g.set(3, 2, "Alive")
  let ca = new_ca(grid=g, rule=fn(grid, x, y) {
    let nbrs = grid.neighbors_moore(x, y)
    let alive = nbrs.count_if(fn(v) { v == "Alive" })
    if grid.get(x, y) == "Alive" {
      if alive == 2 || alive == 3 {
        "Alive"
      } else {
        "Dead"
      }
    } else if alive == 3 {
      "Alive"
    } else {
      "Dead"
    }
  })
  // 初始 3 个活细胞
  assert_eq(ca.count_value("Alive"), 3)
  ca.step()
  // 一步后变为垂直三连，仍然 3 个
  assert_eq(ca.count_value("Alive"), 3)
  ca.step()
  // 两步后恢复水平三连
  assert_eq(ca.count_value("Alive"), 3)
  // 验证周期性：2 步后 (2,2) 应该是 Alive
  assert_eq(ca.current_grid().get(2, 2), "Alive")
}

///|
/// CA：生命游戏 — 区块（稳定结构）
test "ca game_of_life block" {
  let g = @grid2d.new_grid2d(width=5, height=5, default="Dead")
  // 2x2 方块是稳定结构
  g.set(1, 1, "Alive")
  g.set(1, 2, "Alive")
  g.set(2, 1, "Alive")
  g.set(2, 2, "Alive")
  let ca = new_ca(grid=g, rule=fn(grid, x, y) {
    let nbrs = grid.neighbors_moore(x, y)
    let alive = nbrs.count_if(fn(v) { v == "Alive" })
    if grid.get(x, y) == "Alive" {
      if alive == 2 || alive == 3 {
        "Alive"
      } else {
        "Dead"
      }
    } else if alive == 3 {
      "Alive"
    } else {
      "Dead"
    }
  })
  ca.step()
  // 2x2 方块保持不变
  assert_eq(ca.count_value("Alive"), 4)
  assert_eq(ca.current_grid().get(1, 1), "Alive")
  assert_eq(ca.current_grid().get(2, 2), "Alive")
}

///|
/// CA：同步更新验证
test "ca synchronous update" {
  // 所有细胞变成邻居的值（验证同步更新）
  let g = @grid2d.new_grid2d(width=2, height=1, default="A")
  g.set(0, 0, "A")
  g.set(1, 0, "B")
  let ca = new_ca(grid=g, rule=fn(grid, x, y) {
    let nbrs = grid.neighbors_von_neumann(x, y)
    if nbrs.length() > 0 {
      nbrs[0]
    } else {
      grid.get(x, y)
    }
  })
  ca.step()
  // 同步更新：(0,0) 变成 B，(1,0) 变成 A
  assert_eq(ca.current_grid().get(0, 0), "B")
  assert_eq(ca.current_grid().get(1, 0), "A")
}

///|
/// CA：代数计数
test "ca generation count" {
  let g = @grid2d.new_grid2d(width=1, height=1, default="X")
  let ca = new_ca(grid=g, rule=fn(_grid, _x, _y) { "X" })
  for i in 0..<10 {
    ca.step()
    assert_eq(ca.generation_count(), i + 1)
  }
}

///|
/// CA：to_string
test "ca to_string" {
  let g = @grid2d.new_grid2d(width=2, height=2, default="A")
  let ca = new_ca(grid=g, rule=fn(_grid, _x, _y) { "A" })
  let s = ca.to_string()
  assert_true(s.contains("CA"))
  assert_true(s.contains("generation=0"))
}

///|
/// CA：count_value
test "ca count_value" {
  let g = @grid2d.new_grid2d(width=3, height=3, default="Empty")
  g.set(0, 0, "Tree")
  g.set(1, 1, "Tree")
  let ca = new_ca(
    grid=g,
    rule=fn(grid, x, y) { grid.get(x, y) }, // 恒等规则
  )
  assert_eq(ca.count_value("Tree"), 2)
  assert_eq(ca.count_value("Empty"), 7)
  ca.step()
  // 恒等规则不改变状态
  assert_eq(ca.count_value("Tree"), 2)
}
