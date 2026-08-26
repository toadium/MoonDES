///|
/// 2D 网格
///
/// 二维网格，每个格子存储一个 String 值（如细胞状态）。
/// 支持 Moore 邻域（8 邻居）和 Von Neumann 邻域（4 邻居）。
///
/// 适用于：元胞自动机、热传导、森林火灾、城市扩张等空间仿真。
///
/// # Example
/// ```mbt check
/// test {
///   let g = @grid2d.new_grid2d(width=3, height=3, default="Empty")
///   g.set(1, 1, "Tree")
///   assert_eq(g.get(1, 1), "Tree")
///   let nbrs = g.neighbors_moore(1, 1)
///   assert_eq(nbrs.length(), 8) // 3x3 中心有 8 个邻居
/// }
/// ```
pub(all) struct Grid2D {
  width : Int
  height : Int
  cells : Array[String]
}

///|
/// 创建 2D 网格
pub fn new_grid2d(width~ : Int, height~ : Int, default~ : String) -> Grid2D {
  let cells : Array[String] = []
  for _ in 0..<(width * height) {
    cells.push(default)
  }
  { width, height, cells }
}

///|
/// 宽度
pub fn Grid2D::width(self : Grid2D) -> Int {
  self.width
}

///|
/// 高度
pub fn Grid2D::height(self : Grid2D) -> Int {
  self.height
}

///|
/// 边界检查
pub fn Grid2D::in_bounds(self : Grid2D, x : Int, y : Int) -> Bool {
  x >= 0 && x < self.width && y >= 0 && y < self.height
}

///|
/// 读取格子
pub fn Grid2D::get(self : Grid2D, x : Int, y : Int) -> String {
  self.cells[y * self.width + x]
}

///|
/// 写入格子
pub fn Grid2D::set(self : Grid2D, x : Int, y : Int, value : String) -> Unit {
  self.cells[y * self.width + x] = value
}

///|
/// Moore 邻域（8 邻居）
///
/// 返回周围 8 个格子的值（不含自身）。边界外的格子跳过。
pub fn Grid2D::neighbors_moore(
  self : Grid2D,
  x : Int,
  y : Int,
) -> Array[String] {
  let result : Array[String] = []
  for dy in [-1, 0, 1] {
    for dx in [-1, 0, 1] {
      if dx == 0 && dy == 0 {
        continue
      }
      let nx = x + dx
      let ny = y + dy
      if self.in_bounds(nx, ny) {
        result.push(self.get(nx, ny))
      }
    }
  }
  result
}

///|
/// Von Neumann 邻域（4 邻居）
///
/// 返回上下左右 4 个格子的值。边界外的格子跳过。
pub fn Grid2D::neighbors_von_neumann(
  self : Grid2D,
  x : Int,
  y : Int,
) -> Array[String] {
  let result : Array[String] = []
  let offsets = [(0, -1), (0, 1), (-1, 0), (1, 0)]
  for pair in offsets {
    let nx = x + pair.0
    let ny = y + pair.1
    if self.in_bounds(nx, ny) {
      result.push(self.get(nx, ny))
    }
  }
  result
}

///|
/// Moore 邻域坐标（8 邻居位置）
///
/// 返回周围 8 个格子的坐标 (x, y)。边界外的跳过。
pub fn Grid2D::neighbor_coords_moore(
  self : Grid2D,
  x : Int,
  y : Int,
) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  for dy in [-1, 0, 1] {
    for dx in [-1, 0, 1] {
      if dx == 0 && dy == 0 {
        continue
      }
      let nx = x + dx
      let ny = y + dy
      if self.in_bounds(nx, ny) {
        result.push((nx, ny))
      }
    }
  }
  result
}

///|
/// 填充所有格子
pub fn Grid2D::fill(self : Grid2D, value : String) -> Unit {
  for i in 0..<self.cells.length() {
    self.cells[i] = value
  }
}

///|
/// 条件计数
///
/// 统计满足 `predicate` 的格子数量。
pub fn Grid2D::count_if(self : Grid2D, predicate : (String) -> Bool) -> Int {
  let mut count = 0
  for i in 0..<self.cells.length() {
    if predicate(self.cells[i]) {
      count += 1
    }
  }
  count
}

///|
/// 统计特定值
pub fn Grid2D::count_value(self : Grid2D, value : String) -> Int {
  self.count_if(fn(v) { v == value })
}

///|
/// 总格子数
pub fn Grid2D::cell_count(self : Grid2D) -> Int {
  self.width * self.height
}

///|
/// 人类可读描述
pub fn Grid2D::to_string(self : Grid2D) -> String {
  let mut s = "Grid2D (\{self.width}x\{self.height}):\n"
  for y in 0..<self.height {
    let mut row = "  "
    for x in 0..<self.width {
      let v = self.get(x, y)
      // 取首字符作为紧凑显示
      let ch = if v.length() > 0 { v[:1].to_owned() } else { "." }
      row += ch
      if x < self.width - 1 {
        row += " "
      }
    }
    s += row + "\n"
  }
  s
}

///|
/// 复制网格
pub fn Grid2D::copy(self : Grid2D) -> Grid2D {
  let new_cells : Array[String] = []
  for i in 0..<self.cells.length() {
    new_cells.push(self.cells[i])
  }
  { width: self.width, height: self.height, cells: new_cells }
}
