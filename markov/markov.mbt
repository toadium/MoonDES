///|
/// 马尔可夫链
///
/// 离散时间马尔可夫链，状态转移基于概率。
/// 与 FSM 的区别：FSM 转移由事件触发（确定性），Markov 转移由概率驱动（随机性）。
///
/// 适用于：天气模型、市场状态、传染病 SIR 模型、客户旅程等随机过程。
///
/// # Example
/// ```mbt check
/// test {
///   let rng = @random.new_rng()
///   let mc = @markov.new_markov_chain(initial="Sunny", rng~)
///   mc.add_transition("Sunny", "Rainy", 0.3)
///   mc.add_transition("Sunny", "Sunny", 0.7)
///   mc.add_transition("Rainy", "Sunny", 0.5)
///   mc.add_transition("Rainy", "Rainy", 0.5)
///   let next = mc.next_state()
///   assert_true(next == "Sunny" || next == "Rainy")
/// }
/// ```
pub(all) struct MarkovChain {
  mut current_state : String
  transitions : Map[String, Array[(String, Double)]]
  rng : @rand.Rand
  mut step_count : Int
}

///|
/// 创建马尔可夫链
pub fn new_markov_chain(initial~ : String, rng~ : @rand.Rand) -> MarkovChain {
  { current_state: initial, transitions: Map([]), rng, step_count: 0 }
}

///|
/// 添加状态转移
///
/// 从 `from` 到 `to` 的转移概率为 `probability`。
/// 同一 `from` 的所有转移概率之和应为 1.0。
pub fn MarkovChain::add_transition(
  self : MarkovChain,
  from : String,
  to : String,
  probability : Double,
) -> Unit {
  if !self.transitions.contains(from) {
    self.transitions[from] = []
  }
  self.transitions[from].push((to, probability))
}

///|
/// 当前状态
pub fn MarkovChain::current(self : MarkovChain) -> String {
  self.current_state
}

///|
/// 步数
pub fn MarkovChain::step_count(self : MarkovChain) -> Int {
  self.step_count
}

///|
/// 采样下一状态
///
/// 根据当前状态的转移概率，随机采样下一状态。
/// 若当前状态无转移定义，保持不变。
pub fn MarkovChain::next_state(self : MarkovChain) -> String {
  match self.transitions.get(self.current_state) {
    Some(trans) => {
      if trans.length() == 0 {
        return self.current_state
      }
      let r = @random.uniform(self.rng, min=0.0, max=1.0)
      let mut cumul = 0.0
      let mut next = trans[0].0
      for i in 0..<trans.length() {
        cumul += trans[i].1
        if r < cumul {
          next = trans[i].0
          break
        }
      }
      self.current_state = next
      self.step_count += 1
      next
    }
    None => self.current_state
  }
}

///|
/// 多步仿真
///
/// 运行 `n` 步，返回每步的状态序列（含初始状态）。
pub fn MarkovChain::simulate(self : MarkovChain, n : Int) -> Array[String] {
  let result : Array[String] = [self.current_state]
  for _ in 0..<n {
    result.push(self.next_state())
  }
  result
}

///|
/// 状态列表
pub fn MarkovChain::states(self : MarkovChain) -> Array[String] {
  let result : Array[String] = []
  for state in self.transitions.keys() {
    if !result.contains(state) {
      result.push(state)
    }
  }
  for from in self.transitions.keys() {
    for pair in self.transitions[from] {
      if !result.contains(pair.0) {
        result.push(pair.0)
      }
    }
  }
  result
}

///|
/// 转移数
pub fn MarkovChain::transition_count(self : MarkovChain) -> Int {
  let mut count = 0
  for from in self.transitions.keys() {
    count += self.transitions[from].length()
  }
  count
}

///|
/// 是否有转移定义
pub fn MarkovChain::has_transitions(self : MarkovChain, state : String) -> Bool {
  match self.transitions.get(state) {
    Some(trans) => trans.length() > 0
    None => false
  }
}

///|
/// 获取状态的转移概率
///
/// 返回从 `from` 到 `to` 的转移概率。若无定义返回 0.0。
pub fn MarkovChain::probability(
  self : MarkovChain,
  from : String,
  to : String,
) -> Double {
  match self.transitions.get(from) {
    Some(trans) => {
      let mut prob = 0.0
      for pair in trans {
        if pair.0 == to {
          prob = pair.1
          break
        }
      }
      prob
    }
    None => 0.0
  }
}

///|
/// 人类可读描述
pub fn MarkovChain::to_string(self : MarkovChain) -> String {
  let mut s = "MarkovChain (current=\{self.current_state}, steps=\{self.step_count}):\n"
  for from in self.transitions.keys() {
    let trans = self.transitions[from]
    let parts : Array[String] = []
    for pair in trans {
      parts.push("\{pair.0}:\{pair.1}")
    }
    s += "  \{from} -> [\{parts.join(", ")}]\n"
  }
  s
}
