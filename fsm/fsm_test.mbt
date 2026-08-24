// ===========================================================================
// StateMachine — 有限状态机测试
// ===========================================================================

///|
/// StateMachine：基本状态转换
test "fsm basic transition" {
  let sm = new_state_machine(initial="Idle", transitions=[
    transition(from="Idle", to="Working", on="start"),
    transition(from="Working", to="Idle", on="stop"),
  ])
  assert_eq(sm.current(), "Idle")
  let ok = sm.fire("start")
  assert_true(ok)
  assert_eq(sm.current(), "Working")
  let ok2 = sm.fire("stop")
  assert_true(ok2)
  assert_eq(sm.current(), "Idle")
}

///|
/// StateMachine：无匹配转换保持原状
test "fsm no matching transition" {
  let sm = new_state_machine(initial="Idle", transitions=[
    transition(from="Idle", to="Working", on="start"),
  ])
  // "stop" 在 Idle 状态下无匹配
  let ok = sm.fire("stop")
  assert_false(ok)
  assert_eq(sm.current(), "Idle")
}

///|
/// StateMachine：guard 条件拒绝
test "fsm guard rejects" {
  let mut allow = false
  let sm = new_state_machine(initial="Idle", transitions=[
    transition(from="Idle", to="Working", on="start", guard_fn=fn() { allow }),
  ])
  // guard 拒绝
  let ok1 = sm.fire("start")
  assert_false(ok1)
  assert_eq(sm.current(), "Idle")
  // guard 允许
  allow = true
  let ok2 = sm.fire("start")
  assert_true(ok2)
  assert_eq(sm.current(), "Working")
}

///|
/// StateMachine：guard 条件允许
test "fsm guard allows" {
  let sm = new_state_machine(initial="Closed", transitions=[
    transition(from="Closed", to="Open", on="open", guard_fn=fn() { true }),
  ])
  let ok = sm.fire("open")
  assert_true(ok)
  assert_eq(sm.current(), "Open")
}

///|
/// StateMachine：on_enter / on_exit 回调
test "fsm on_enter on_exit callbacks" {
  let sm = new_state_machine(initial="Idle", transitions=[
    transition(from="Idle", to="Working", on="start"),
    transition(from="Working", to="Done", on="finish"),
  ])
  let log : Array[String] = []
  sm.on_exit("Idle", fn(_s) { log.push("exit Idle") })
  sm.on_enter("Working", fn(_s) { log.push("enter Working") })
  sm.on_exit("Working", fn(_s) { log.push("exit Working") })
  sm.on_enter("Done", fn(_s) { log.push("enter Done") })
  ignore(sm.fire("start"))
  ignore(sm.fire("finish"))
  assert_eq(log.length(), 4)
  assert_eq(log[0], "exit Idle")
  assert_eq(log[1], "enter Working")
  assert_eq(log[2], "exit Working")
  assert_eq(log[3], "enter Done")
}

///|
/// StateMachine：历史轨迹
test "fsm history" {
  let sm = new_state_machine(initial="A", transitions=[
    transition(from="A", to="B", on="ab"),
    transition(from="B", to="C", on="bc"),
    transition(from="C", to="A", on="ca"),
  ])
  ignore(sm.fire("ab"))
  ignore(sm.fire("bc"))
  ignore(sm.fire("ca"))
  let h = sm.history()
  assert_eq(h.length(), 4)
  assert_eq(h[0], "A")
  assert_eq(h[1], "B")
  assert_eq(h[2], "C")
  assert_eq(h[3], "A")
  assert_eq(sm.transition_count(), 3)
}

///|
/// StateMachine：多事件同状态
test "fsm multiple events from same state" {
  let sm = new_state_machine(initial="Idle", transitions=[
    transition(from="Idle", to="Working", on="start"),
    transition(from="Idle", to="Error", on="fail"),
    transition(from="Working", to="Done", on="finish"),
    transition(from="Working", to="Error", on="fail"),
  ])
  assert_true(sm.can_fire("start"))
  assert_true(sm.can_fire("fail"))
  let events = sm.available_events()
  assert_eq(events.length(), 2)
  // 选择 start
  ignore(sm.fire("start"))
  assert_eq(sm.current(), "Working")
  // Working 状态下有 finish 和 fail
  let events2 = sm.available_events()
  assert_eq(events2.length(), 2)
}

///|
/// StateMachine：is_in 状态判断
test "fsm is_in" {
  let sm = new_state_machine(initial="Idle", transitions=[
    transition(from="Idle", to="Running", on="go"),
  ])
  assert_true(sm.is_in("Idle"))
  assert_false(sm.is_in("Running"))
  ignore(sm.fire("go"))
  assert_true(sm.is_in("Running"))
  assert_false(sm.is_in("Idle"))
}

///|
/// StateMachine：can_fire 查询
test "fsm can_fire" {
  let sm = new_state_machine(initial="Idle", transitions=[
    transition(from="Idle", to="Working", on="start"),
    transition(from="Working", to="Idle", on="stop"),
  ])
  assert_true(sm.can_fire("start"))
  assert_false(sm.can_fire("stop"))
  ignore(sm.fire("start"))
  assert_false(sm.can_fire("start"))
  assert_true(sm.can_fire("stop"))
}

///|
/// StateMachine：reset 重置
test "fsm reset" {
  let sm = new_state_machine(initial="A", transitions=[
    transition(from="A", to="B", on="ab"),
  ])
  ignore(sm.fire("ab"))
  assert_eq(sm.current(), "B")
  sm.reset("A")
  assert_eq(sm.current(), "A")
  assert_eq(sm.transition_count(), 0)
}

///|
/// StateMachine：循环状态转换
test "fsm cyclic transitions" {
  let sm = new_state_machine(initial="Red", transitions=[
    transition(from="Red", to="Green", on="next"),
    transition(from="Green", to="Yellow", on="next"),
    transition(from="Yellow", to="Red", on="next"),
  ])
  // 红绿灯循环 3 次
  for _ in 0..<3 {
    ignore(sm.fire("next")) // Red → Green
    assert_eq(sm.current(), "Green")
    ignore(sm.fire("next")) // Green → Yellow
    assert_eq(sm.current(), "Yellow")
    ignore(sm.fire("next")) // Yellow → Red
    assert_eq(sm.current(), "Red")
  }
  assert_eq(sm.transition_count(), 9)
}

///|
/// StateMachine：工厂设备完整生命周期
test "fsm factory machine lifecycle" {
  let sm = new_state_machine(initial="Idle", transitions=[
    transition(from="Idle", to="Working", on="start"),
    transition(from="Working", to="Idle", on="complete"),
    transition(from="Working", to="Broken", on="breakdown"),
    transition(from="Broken", to="Repairing", on="repair"),
    transition(from="Repairing", to="Idle", on="fixed"),
  ])
  // 正常工作周期
  ignore(sm.fire("start"))
  assert_eq(sm.current(), "Working")
  ignore(sm.fire("complete"))
  assert_eq(sm.current(), "Idle")
  // 故障周期
  ignore(sm.fire("start"))
  ignore(sm.fire("breakdown"))
  assert_eq(sm.current(), "Broken")
  ignore(sm.fire("repair"))
  assert_eq(sm.current(), "Repairing")
  ignore(sm.fire("fixed"))
  assert_eq(sm.current(), "Idle")
  // 验证历史
  let h = sm.history()
  assert_eq(h.length(), 7) // Idle + 6 transitions
}
