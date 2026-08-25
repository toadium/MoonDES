///|
/// 状态机状态标识
pub type State = String

///|
/// 事件标识
pub type Event = String

///|
/// 状态转换规则
///
/// 定义从 `from` 状态到 `to` 状态的转换，由 `event` 触发。
/// 可选 `guard_fn` 谓词，返回 `true` 时才允许转换。
///
/// # Example
/// ```mbt check
/// test {
///   let t = @fsm.transition(from="Idle", to="Working", on="start")
///   inspect(t.from, content="Idle")
///   inspect(t.to, content="Working")
///   inspect(t.on, content="start")
/// }
/// ```
pub(all) struct Transition {
  from : State
  to : State
  on : Event
  guard_fn : () -> Bool
}

///|
/// 创建状态转换规则
pub fn transition(
  from~ : State,
  to~ : State,
  on~ : Event,
  guard_fn? : () -> Bool = fn() { true },
) -> Transition {
  { from, to, on, guard_fn }
}

///|
/// 状态转换回调类型
pub type StateCallback = (State) -> Unit

///|
/// 有限状态机
///
/// 维护当前状态和转换规则集合。`fire(event)` 查找当前状态下匹配
/// `event` 的转换规则，通过 guard 检查后执行状态转换：
/// 1. 调用旧状态的 `on_exit` 回调
/// 2. 更新当前状态
/// 3. 调用新状态的 `on_enter` 回调
///
/// 无匹配转换时保持原状并返回 `false`。
///
/// # Example
/// ```mbt check
/// test {
///   let sm = @fsm.new_state_machine(initial="Idle", transitions=[
///     @fsm.transition(from="Idle", to="Working", on="start"),
///     @fsm.transition(from="Working", to="Idle", on="stop"),
///   ])
///   inspect(sm.current(), content="Idle")
///   let ok = sm.fire("start")
///   assert_true(ok)
///   inspect(sm.current(), content="Working")
///   let ok2 = sm.fire("stop")
///   assert_true(ok2)
///   inspect(sm.current(), content="Idle")
/// }
/// ```
pub(all) struct StateMachine {
  mut current_state : State
  transitions : Array[Transition]
  enter_callbacks : Map[State, StateCallback]
  exit_callbacks : Map[State, StateCallback]
  mut history : Array[State]
}

///|
/// 创建有限状态机
///
/// - `initial`：初始状态
/// - `transitions`：转换规则列表
pub fn new_state_machine(
  initial~ : State,
  transitions~ : Array[Transition],
) -> StateMachine {
  let sm : StateMachine = {
    current_state: initial,
    transitions,
    enter_callbacks: {},
    exit_callbacks: {},
    history: [initial],
  }
  sm
}

///|
/// 注册状态进入回调
///
/// 每次转换进入 `state` 时调用 `callback`。
pub fn StateMachine::on_enter(
  self : StateMachine,
  state : State,
  callback : StateCallback,
) -> Unit {
  self.enter_callbacks[state] = callback
}

///|
/// 注册状态退出回调
///
/// 每次转换离开 `state` 时调用 `callback`。
pub fn StateMachine::on_exit(
  self : StateMachine,
  state : State,
  callback : StateCallback,
) -> Unit {
  self.exit_callbacks[state] = callback
}

///|
/// 触发事件
///
/// 查找当前状态下匹配 `event` 的转换规则，通过 guard 检查后执行转换。
/// 返回 `true` 表示转换成功，`false` 表示无匹配转换或 guard 拒绝。
pub fn StateMachine::fire(self : StateMachine, event : Event) -> Bool {
  for t in self.transitions {
    if t.from == self.current_state && t.on == event {
      if (t.guard_fn)() {
        // on_exit
        match self.exit_callbacks.get(self.current_state) {
          Some(cb) => cb(self.current_state)
          None => ()
        }
        // 转换
        self.current_state = t.to
        self.history.push(t.to)
        // on_enter
        match self.enter_callbacks.get(t.to) {
          Some(cb) => cb(t.to)
          None => ()
        }
        return true
      }
      // guard 拒绝，继续查找其他匹配
    }
  }
  false
}

///|
/// 当前状态
pub fn StateMachine::current(self : StateMachine) -> State {
  self.current_state
}

///|
/// 是否处于指定状态
pub fn StateMachine::is_in(self : StateMachine, state : State) -> Bool {
  self.current_state == state
}

///|
/// 状态历史轨迹
pub fn StateMachine::history(self : StateMachine) -> Array[State] {
  self.history
}

///|
/// 状态转换次数
pub fn StateMachine::transition_count(self : StateMachine) -> Int {
  self.history.length() - 1
}

///|
/// 可从当前状态触发的事件列表
pub fn StateMachine::available_events(self : StateMachine) -> Array[Event] {
  let events : Array[Event] = []
  for t in self.transitions {
    if t.from == self.current_state {
      events.push(t.on)
    }
  }
  events
}

///|
/// 是否可以从当前状态触发指定事件
pub fn StateMachine::can_fire(self : StateMachine, event : Event) -> Bool {
  for t in self.transitions {
    if t.from == self.current_state && t.on == event {
      return true
    }
  }
  false
}

///|
/// 重置到指定状态
///
/// 清空历史，设置当前状态为 `state`。
pub fn StateMachine::reset(self : StateMachine, state : State) -> Unit {
  self.current_state = state
  self.history = [state]
}
