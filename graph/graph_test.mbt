// ===========================================================================
// Graph — 图网络测试
// ===========================================================================

///|
/// Graph：基本添加
test "graph basic add" {
  let g = new_graph()
  g.add_node("A")
  g.add_node("B")
  assert_eq(g.node_count(), 2)
  assert_eq(g.edge_count(), 0)
  assert_true(g.is_empty() == false)
}

///|
/// Graph：添加边
test "graph add_edge" {
  let g = new_graph()
  g.add_edge("A", "B")
  assert_eq(g.node_count(), 2)
  assert_eq(g.edge_count(), 1)
  assert_true(g.has_edge("A", "B"))
  assert_true(g.has_edge("B", "A")) // 无向
}

///|
/// Graph：邻居和度数
test "graph neighbors degree" {
  let g = new_graph()
  g.add_edge("A", "B")
  g.add_edge("A", "C")
  g.add_edge("A", "D")
  let nbrs = g.neighbors("A")
  assert_eq(nbrs.length(), 3)
  assert_eq(g.degree("A"), 3)
  assert_eq(g.degree("B"), 1)
}

///|
/// Graph：BFS 遍历
test "graph bfs" {
  let g = new_graph()
  g.add_edge("A", "B")
  g.add_edge("A", "C")
  g.add_edge("B", "D")
  g.add_edge("C", "D")
  let order = g.bfs("A")
  assert_eq(order.length(), 4)
  assert_eq(order[0], "A") // 起点首先访问
  // B 和 C 都是 A 的邻居，在第二层
  assert_true(order[1] == "B" || order[1] == "C")
  assert_true(order[2] == "B" || order[2] == "C")
  assert_eq(order[3], "D") // D 在第三层
}

///|
/// Graph：最短路径
test "graph shortest_path" {
  let g = new_graph()
  g.add_edge("A", "B")
  g.add_edge("B", "C")
  g.add_edge("C", "D")
  g.add_edge("A", "D") // A→D 直接连边
  match g.shortest_path("A", "D") {
    Some(path) => assert_eq(path.length(), 2) // A→D
    None => assert_true(false)
  }
  match g.shortest_path("A", "C") {
    Some(path) => {
      assert_eq(path.length(), 3) // A→B→C or A→D→C
      assert_eq(path[0], "A")
      assert_eq(path[2], "C")
    }
    None => assert_true(false)
  }
}

///|
/// Graph：不可达路径
test "graph no path" {
  let g = new_graph()
  g.add_edge("A", "B")
  g.add_edge("C", "D")
  match g.shortest_path("A", "D") {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
/// Graph：连通分量
test "graph connected_components" {
  let g = new_graph()
  g.add_edge("A", "B")
  g.add_edge("B", "C")
  g.add_edge("D", "E")
  let comps = g.connected_components()
  assert_eq(comps.length(), 2)
  // 一个分量有 3 个节点，另一个有 2 个
  let sizes = [comps[0].length(), comps[1].length()]
  assert_true(sizes.contains(3))
  assert_true(sizes.contains(2))
}

///|
/// Graph：单个连通分量
test "graph single component" {
  let g = new_graph()
  g.add_edge("A", "B")
  g.add_edge("B", "C")
  let comps = g.connected_components()
  assert_eq(comps.length(), 1)
  assert_eq(comps[0].length(), 3)
}

///|
/// Graph：空图
test "graph empty" {
  let g = new_graph()
  assert_true(g.is_empty())
  assert_eq(g.node_count(), 0)
  assert_eq(g.edge_count(), 0)
  let comps = g.connected_components()
  assert_eq(comps.length(), 0)
}

///|
/// Graph：重复边不重复添加
test "graph duplicate edge" {
  let g = new_graph()
  g.add_edge("A", "B")
  g.add_edge("A", "B") // 重复
  g.add_edge("B", "A") // 重复（无向）
  assert_eq(g.edge_count(), 1)
  assert_eq(g.degree("A"), 1)
}

///|
/// Graph：自环
test "graph self_loop" {
  let g = new_graph()
  g.add_edge("A", "A")
  assert_eq(g.node_count(), 1)
  assert_eq(g.edge_count(), 1)
  assert_true(g.has_edge("A", "A"))
}

///|
/// Graph：to_string
test "graph to_string" {
  let g = new_graph()
  g.add_edge("Alice", "Bob")
  g.add_edge("Bob", "Carol")
  let s = g.to_string()
  assert_true(s.contains("Graph"))
  assert_true(s.contains("Alice"))
  assert_true(s.contains("Bob"))
  assert_true(s.contains("Carol"))
}

///|
/// Graph：所有节点
test "graph nodes" {
  let g = new_graph()
  g.add_edge("X", "Y")
  g.add_node("Z")
  let nodes = g.nodes()
  assert_eq(nodes.length(), 3)
  assert_true(nodes.contains("X"))
  assert_true(nodes.contains("Y"))
  assert_true(nodes.contains("Z"))
}
