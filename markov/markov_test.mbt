// ===========================================================================
// MarkovChain — 马尔可夫链测试
// ===========================================================================

///|
/// MarkovChain：基本状态转移
test "markov basic transition" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="A", rng~)
  mc.add_transition("A", "B", 1.0)
  mc.add_transition("B", "A", 1.0)
  assert_eq(mc.current(), "A")
  let next = mc.next_state()
  assert_eq(next, "B")
  assert_eq(mc.step_count(), 1)
  let next2 = mc.next_state()
  assert_eq(next2, "A")
  assert_eq(mc.step_count(), 2)
}

///|
/// MarkovChain：概率采样
test "markov probabilistic" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="A", rng~)
  mc.add_transition("A", "A", 0.5)
  mc.add_transition("A", "B", 0.5)
  // 多次采样，结果应该是 A 或 B
  for _ in 0..<100 {
    let s = mc.next_state()
    assert_true(s == "A" || s == "B")
    // 重置回 A 继续测试
    if s == "B" {
      mc.add_transition("B", "A", 1.0)
      ignore(mc.next_state())
    }
  }
}

///|
/// MarkovChain：多步仿真
test "markov simulate" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="S", rng~)
  mc.add_transition("S", "S", 0.5)
  mc.add_transition("S", "I", 0.5)
  mc.add_transition("I", "I", 0.3)
  mc.add_transition("I", "R", 0.7)
  mc.add_transition("R", "R", 1.0)
  let path = mc.simulate(20)
  assert_eq(path.length(), 21) // 初始 + 20 步
  assert_eq(path[0], "S")
  // 最终应该到达 R（吸收态）
  assert_eq(path[20], "R")
}

///|
/// MarkovChain：吸收态
test "markov absorbing" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="Start", rng~)
  mc.add_transition("Start", "Start", 0.5)
  mc.add_transition("Start", "End", 0.5)
  mc.add_transition("End", "End", 1.0)
  let path = mc.simulate(50)
  // 最终一定到达 End
  assert_eq(path[50], "End")
}

///|
/// MarkovChain：自环
test "markov self_loop" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="X", rng~)
  mc.add_transition("X", "X", 1.0)
  let next = mc.next_state()
  assert_eq(next, "X")
  let path = mc.simulate(10)
  for s in path {
    assert_eq(s, "X")
  }
}

///|
/// MarkovChain：无转移定义保持不变
test "markov no transitions" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="Isolated", rng~)
  let next = mc.next_state()
  assert_eq(next, "Isolated")
  assert_eq(mc.step_count(), 0)
}

///|
/// MarkovChain：转移概率查询
test "markov probability query" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="A", rng~)
  mc.add_transition("A", "B", 0.3)
  mc.add_transition("A", "C", 0.7)
  assert_eq(mc.probability("A", "B"), 0.3)
  assert_eq(mc.probability("A", "C"), 0.7)
  assert_eq(mc.probability("A", "D"), 0.0) // 不存在
  assert_eq(mc.probability("B", "A"), 0.0) // 不存在
}

///|
/// MarkovChain：状态列表
test "markov states" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="A", rng~)
  mc.add_transition("A", "B", 0.5)
  mc.add_transition("A", "C", 0.5)
  mc.add_transition("B", "A", 1.0)
  mc.add_transition("C", "A", 1.0)
  let states = mc.states()
  assert_eq(states.length(), 3)
  assert_true(states.contains("A"))
  assert_true(states.contains("B"))
  assert_true(states.contains("C"))
}

///|
/// MarkovChain：转移数
test "markov transition_count" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="A", rng~)
  mc.add_transition("A", "B", 0.5)
  mc.add_transition("A", "C", 0.5)
  mc.add_transition("B", "A", 1.0)
  mc.add_transition("C", "A", 1.0)
  assert_eq(mc.transition_count(), 4)
}

///|
/// MarkovChain：has_transitions
test "markov has_transitions" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="A", rng~)
  mc.add_transition("A", "B", 1.0)
  assert_true(mc.has_transitions("A"))
  assert_false(mc.has_transitions("B"))
  assert_false(mc.has_transitions("C"))
}

///|
/// MarkovChain：to_string
test "markov to_string" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="S", rng~)
  mc.add_transition("S", "I", 0.3)
  mc.add_transition("S", "S", 0.7)
  let s = mc.to_string()
  assert_true(s.contains("MarkovChain"))
  assert_true(s.contains("S"))
  assert_true(s.contains("I"))
}

///|
/// MarkovChain：SIR 模型基本流程
test "markov sir model" {
  let rng = @random.new_rng()
  let mc = new_markov_chain(initial="Susceptible", rng~)
  mc.add_transition("Susceptible", "Susceptible", 0.8)
  mc.add_transition("Susceptible", "Infected", 0.2)
  mc.add_transition("Infected", "Infected", 0.5)
  mc.add_transition("Infected", "Recovered", 0.5)
  mc.add_transition("Recovered", "Recovered", 1.0)
  let path = mc.simulate(100)
  assert_eq(path[0], "Susceptible")
  // 最终到达 Recovered（吸收态）
  assert_eq(path[100], "Recovered")
  // 中间应该经过 Infected
  let mut has_infected = false
  for s in path {
    if s == "Infected" {
      has_infected = true
    }
  }
  assert_true(has_infected)
}
