///|
/// 进程状态快照
pub(all) struct ProcessSnapshot {
  name : String
  status : String
}

///|
/// FSM 状态快照
pub(all) struct FsmSnapshot {
  current_state : String
  transition_count : Int
  history : Array[String]
}

///|
/// 统计快照
pub(all) struct StatsSnapshot {
  count : Int
  mean : Double
  stddev : Double
  min : Double
  max : Double
}

///|
/// 仿真快照
///
/// 捕获仿真环境的关键状态，用于检查点、日志、恢复。
/// 注意：回调函数无法序列化，快照只保存数据状态。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=100.0)
///   let snap = @serialize.new_snapshot(env)
///   inspect(snap.time, content="0")
///   inspect(snap.event_count, content="0")
/// }
/// ```
pub(all) struct SimulationSnapshot {
  time : Double
  until : Double
  event_count : Int
  is_finished : Bool
  process_states : Array[ProcessSnapshot]
  fsm_states : Array[FsmSnapshot]
  stats_data : Array[StatsSnapshot]
}

///|
/// 创建仿真快照
///
/// 从仿真环境捕获当前状态。可选传入进程列表和 FSM 列表。
pub fn new_snapshot(env : @core.SimulationEnv) -> SimulationSnapshot {
  {
    time: env.now(),
    until: 0.0, // env 不暴露 until，设为 0
    event_count: env.event_count(),
    is_finished: env.is_finished(),
    process_states: [],
    fsm_states: [],
    stats_data: [],
  }
}

///|
/// 添加进程状态到快照
pub fn SimulationSnapshot::add_process(
  self : SimulationSnapshot,
  process : @process.Process,
) -> Unit {
  let status_str = match process.status() {
    @process.Created => "Created"
    @process.Running => "Running"
    @process.Suspended => "Suspended"
    @process.Terminated => "Terminated"
  }
  self.process_states.push({ name: process.name(), status: status_str })
}

///|
/// 添加 FSM 状态到快照
pub fn SimulationSnapshot::add_fsm(
  self : SimulationSnapshot,
  sm : @fsm.StateMachine,
) -> Unit {
  self.fsm_states.push({
    current_state: sm.current(),
    transition_count: sm.transition_count(),
    history: sm.history(),
  })
}

///|
/// 添加统计数据到快照
pub fn SimulationSnapshot::add_stats(
  self : SimulationSnapshot,
  data : Array[Double],
) -> Unit {
  if data.length() > 0 {
    let s = @stats.summary(data)
    self.stats_data.push({
      count: data.length(),
      mean: s.mean,
      stddev: s.stddev,
      min: s.min,
      max: s.max,
    })
  }
}

///|
/// 快照转 JSON 字符串
///
/// 将快照序列化为 JSON 格式字符串，用于持久化或传输。
pub fn SimulationSnapshot::to_json(self : SimulationSnapshot) -> String {
  // 手动构建 JSON
  let mut s = "{"
  s += "\"time\":\{self.time},"
  s += "\"event_count\":\{self.event_count},"
  s += "\"is_finished\":\{self.is_finished},"
  // process_states
  s += "\"processes\":["
  for i in 0..<self.process_states.length() {
    if i > 0 {
      s += ","
    }
    let p = self.process_states[i]
    s += "{\"name\":\"\{p.name}\",\"status\":\"\{p.status}\"}"
  }
  s += "],"
  // fsm_states
  s += "\"fsms\":["
  for i in 0..<self.fsm_states.length() {
    if i > 0 {
      s += ","
    }
    let f = self.fsm_states[i]
    s += "{\"current_state\":\"\{f.current_state}\",\"transition_count\":\{f.transition_count}}"
  }
  s += "],"
  // stats_data
  s += "\"stats\":["
  for i in 0..<self.stats_data.length() {
    if i > 0 {
      s += ","
    }
    let st = self.stats_data[i]
    s += "{\"count\":\{st.count},\"mean\":\{st.mean},\"stddev\":\{st.stddev},\"min\":\{st.min},\"max\":\{st.max}}"
  }
  s += "]"
  s += "}"
  s
}

///|
/// 快照摘要（人类可读）
///
/// 生成多行文本摘要，适合日志输出。
pub fn SimulationSnapshot::summary(self : SimulationSnapshot) -> String {
  let mut s = "Simulation Snapshot\n"
  s += "  Time: \{self.time}\n"
  s += "  Events: \{self.event_count}\n"
  s += "  Finished: \{self.is_finished}\n"
  s += "  Processes: \{self.process_states.length()}\n"
  for p in self.process_states {
    s += "    - \{p.name} [\{p.status}]\n"
  }
  s += "  FSMs: \{self.fsm_states.length()}\n"
  for f in self.fsm_states {
    s += "    - state=\{f.current_state}, transitions=\{f.transition_count}\n"
  }
  s += "  Stats: \{self.stats_data.length()}\n"
  for i in 0..<self.stats_data.length() {
    let st = self.stats_data[i]
    s += "    [\{i}] count=\{st.count}, mean=\{st.mean}, stddev=\{st.stddev}\n"
  }
  s
}
