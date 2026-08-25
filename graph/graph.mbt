///|
/// 图
///
/// 基于邻接表的无向图，节点类型为 String。
/// 支持：添加节点/边、邻居查询、度数、BFS 遍历、最短路径、连通分量。
///
/// 适用于：社交网络、拓扑分析、路径规划等场景。
///
/// # Example
/// ```mbt check
/// test {
///   let g = @graph.new_graph()
///   g.add_edge("Alice", "Bob")
///   g.add_edge("Bob", "Carol")
///   assert_eq(g.node_count(), 3)
///   assert_eq(g.degree("Bob"), 2)
///   let path = g.shortest_path("Alice", "Carol")
///   match path {
///     Some(p) => assert_eq(p.length(), 3) // Alice→Bob→Carol
///     None => assert_true(false)
///   }
/// }
/// ```
pub(all) struct Graph {
  adj : Map[String, Array[String]]
  mut edge_cnt : Int
}

///|
/// 创建图
pub fn new_graph() -> Graph {
  { adj: Map([]), edge_cnt: 0 }
}

///|
/// 添加节点
pub fn Graph::add_node(self : Graph, node : String) -> Unit {
  if !self.adj.contains(node) {
    self.adj[node] = []
  }
}

///|
/// 添加无向边
///
/// 自动添加两端节点（若不存在）。重复边不重复添加。
pub fn Graph::add_edge(self : Graph, from : String, to : String) -> Unit {
  self.add_node(from)
  self.add_node(to)
  if !self.adj[from].contains(to) {
    self.adj[from].push(to)
    self.adj[to].push(from)
    self.edge_cnt += 1
  }
}

///|
/// 邻居列表
pub fn Graph::neighbors(self : Graph, node : String) -> Array[String] {
  match self.adj.get(node) {
    Some(nbrs) => nbrs
    None => []
  }
}

///|
/// 是否有边
pub fn Graph::has_edge(self : Graph, from : String, to : String) -> Bool {
  match self.adj.get(from) {
    Some(nbrs) => nbrs.contains(to)
    None => false
  }
}

///|
/// 节点度数
pub fn Graph::degree(self : Graph, node : String) -> Int {
  self.neighbors(node).length()
}

///|
/// 节点数
pub fn Graph::node_count(self : Graph) -> Int {
  self.adj.length()
}

///|
/// 边数
pub fn Graph::edge_count(self : Graph) -> Int {
  self.edge_cnt
}

///|
/// BFS 遍历
///
/// 从 `start` 出发，广度优先遍历所有可达节点，返回访问顺序。
pub fn Graph::bfs(self : Graph, start : String) -> Array[String] {
  let visited : Map[String, Bool] = Map([])
  let queue : Array[String] = []
  let result : Array[String] = []
  if !self.adj.contains(start) {
    return result
  }
  visited[start] = true
  queue.push(start)
  while queue.length() > 0 {
    let node = queue.remove(0)
    result.push(node)
    for nbr in self.neighbors(node) {
      if !visited.contains(nbr) {
        visited[nbr] = true
        queue.push(nbr)
      }
    }
  }
  result
}

///|
/// 最短路径
///
/// BFS 求无权图最短路径。返回路径节点序列（含起点和终点）。
/// 若不可达或起点/终点不存在，返回 None。
pub fn Graph::shortest_path(
  self : Graph,
  start : String,
  target : String,
) -> Array[String]? {
  if !self.adj.contains(start) || !self.adj.contains(target) {
    return None
  }
  if start == target {
    return Some([start])
  }
  let visited : Map[String, Bool] = Map([])
  let parent : Map[String, String] = Map([])
  let queue : Array[String] = []
  visited[start] = true
  queue.push(start)
  let mut found = false
  while queue.length() > 0 && !found {
    let node = queue.remove(0)
    for nbr in self.neighbors(node) {
      if !visited.contains(nbr) {
        visited[nbr] = true
        parent[nbr] = node
        if nbr == target {
          found = true
          break
        }
        queue.push(nbr)
      }
    }
  }
  if !found {
    return None
  }
  // 回溯路径
  let path : Array[String] = []
  let mut cur = target
  path.push(cur)
  while cur != start {
    match parent.get(cur) {
      Some(p) => {
        path.push(p)
        cur = p
      }
      None => return None
    }
  }
  // 手动反转
  let reversed : Array[String] = []
  for i in 0..<path.length() {
    reversed.push(path[path.length() - 1 - i])
  }
  Some(reversed)
}

///|
/// 连通分量
///
/// 返回所有连通分量，每个分量是一个节点列表。
pub fn Graph::connected_components(self : Graph) -> Array[Array[String]] {
  let visited : Map[String, Bool] = Map([])
  let components : Array[Array[String]] = []
  for node in self.adj.keys() {
    if !visited.contains(node) {
      let comp = self.bfs(node)
      for n in comp {
        visited[n] = true
      }
      components.push(comp)
    }
  }
  components
}

///|
/// 是否为空图
pub fn Graph::is_empty(self : Graph) -> Bool {
  self.adj.length() == 0
}

///|
/// 所有节点
pub fn Graph::nodes(self : Graph) -> Array[String] {
  let result : Array[String] = []
  for node in self.adj.keys() {
    result.push(node)
  }
  result
}

///|
/// 人类可读描述
pub fn Graph::to_string(self : Graph) -> String {
  let mut s = "Graph (\{self.node_count()} nodes, \{self.edge_count()} edges):\n"
  for node in self.adj.keys() {
    let nbrs = self.neighbors(node)
    s += "  \{node} → [\{nbrs.join(", ")}]\n"
  }
  s
}
