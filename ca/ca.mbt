///|
/// 元胞自动机
///
/// 基于 Grid2D 的元胞自动机引擎。每个时间步，根据局部规则更新所有细胞。
/// 规则是一个回调函数：(当前网格, x, y) -> 新值。
///
/// 适用于：生命游戏、森林火灾、热传导、城市扩张等网格仿真。
///
/// # Example
/// ```mbt check
/// test {
///   let g = @grid2d.new_grid2d(width=3, height=3, default="Dead")
///   g.set(1, 1, "Alive")
///   let ca = @ca.new_ca(grid=g, rule=fn(grid, x, y) {
///     let nbrs = grid.neighbors_moore(x, y)
///     let alive_count = nbrs.count_if(fn(v) { v == "Alive" })
///     if grid.get(x, y) == "Alive" {
///       if alive_count == 2 || alive_count == 3 {
///         "Alive"
///       } else {
///         "Dead"
///       }
///     } else if alive_count == 3 {
///       "Alive"
///     } else {
///       "Dead"
///     }
///   })
///   ca.step()
///   assert_eq(ca.current_grid().get(1, 1), "Dead") // 孤立细胞死亡
/// }
/// ```
pub(all) struct CellularAutomaton {
  grid : @grid2d.Grid2D
  rule : (@grid2d.Grid2D, Int, Int) -> String
  mut generation : Int
}

///|
/// 创建元胞自动机
pub fn new_ca(
  grid~ : @grid2d.Grid2D,
  rule~ : (@grid2d.Grid2D, Int, Int) -> String,
) -> CellularAutomaton {
  { grid, rule, generation: 0 }
}

///|
/// 演化一步
///
/// 根据规则同步更新所有细胞。所有细胞基于当前状态计算新状态，
/// 然后一次性替换（同步更新，非异步）。
pub fn CellularAutomaton::step(self : CellularAutomaton) -> Unit {
  let w = self.grid.width()
  let h = self.grid.height()
  // 先计算所有新值
  let new_values : Array[String] = []
  for y in 0..<h {
    for x in 0..<w {
      new_values.push((self.rule)(self.grid, x, y))
    }
  }
  // 再一次性写入
  for y in 0..<h {
    for x in 0..<w {
      self.grid.set(x, y, new_values[y * w + x])
    }
  }
  self.generation += 1
}

///|
/// 演化多步
pub fn CellularAutomaton::evolve(self : CellularAutomaton, n : Int) -> Unit {
  for _ in 0..<n {
    self.step()
  }
}

///|
/// 当前网格
pub fn CellularAutomaton::current_grid(
  self : CellularAutomaton,
) -> @grid2d.Grid2D {
  self.grid
}

///|
/// 当前代数
pub fn CellularAutomaton::generation_count(self : CellularAutomaton) -> Int {
  self.generation
}

///|
/// 统计特定值的数量
pub fn CellularAutomaton::count_value(
  self : CellularAutomaton,
  value : String,
) -> Int {
  self.grid.count_value(value)
}

///|
/// 人类可读描述
pub fn CellularAutomaton::to_string(self : CellularAutomaton) -> String {
  let mut s = "CA (generation=\{self.generation}):\n"
  s += self.grid.to_string()
  s
}
