// ===========================================================================
// Serialize — 序列化测试
// ===========================================================================

///|
/// Serialize：基本快照创建
test "serialize basic snapshot" {
  let env = @core.new_env(until=100.0)
  let snap = new_snapshot(env)
  assert_eq(snap.time, 0.0)
  assert_eq(snap.event_count, 0)
  assert_false(snap.is_finished)
  assert_eq(snap.process_states.length(), 0)
  assert_eq(snap.fsm_states.length(), 0)
  assert_eq(snap.stats_data.length(), 0)
}

///|
/// Serialize：运行后快照
test "serialize after run" {
  let env = @core.new_env(until=50.0)
  ignore(
    @process.process(env, name="worker", behavior=fn(_p) {
      @process.Timeout(duration=10.0, next=fn() { @process.Done })
    }),
  )
  env.run()
  let snap = new_snapshot(env)
  assert_eq(snap.time, 50.0)
  assert_true(snap.is_finished)
  assert_true(snap.event_count > 0)
}

///|
/// Serialize：添加进程状态
test "serialize add_process" {
  let env = @core.new_env(until=50.0)
  let p = @process.process(env, name="p1", behavior=fn(_p) {
    @process.Timeout(duration=10.0, next=fn() { @process.Done })
  })
  let snap = new_snapshot(env)
  snap.add_process(p)
  assert_eq(snap.process_states.length(), 1)
  assert_eq(snap.process_states[0].name, "p1")
  // 进程刚创建，应该是 Running 或 Created
  assert_true(snap.process_states[0].status.length() > 0)
  env.run()
}

///|
/// Serialize：添加 FSM 状态
test "serialize add_fsm" {
  let env = @core.new_env(until=10.0)
  let sm = @fsm.new_state_machine(initial="Idle", transitions=[
    @fsm.transition(from="Idle", to="Working", on="start"),
    @fsm.transition(from="Working", to="Done", on="finish"),
  ])
  ignore(sm.fire("start"))
  let snap = new_snapshot(env)
  snap.add_fsm(sm)
  assert_eq(snap.fsm_states.length(), 1)
  assert_eq(snap.fsm_states[0].current_state, "Working")
  assert_eq(snap.fsm_states[0].transition_count, 1)
  assert_eq(snap.fsm_states[0].history.length(), 2)
}

///|
/// Serialize：添加统计数据
test "serialize add_stats" {
  let env = @core.new_env(until=10.0)
  let data = [1.0, 2.0, 3.0, 4.0, 5.0]
  let snap = new_snapshot(env)
  snap.add_stats(data)
  assert_eq(snap.stats_data.length(), 1)
  assert_eq(snap.stats_data[0].count, 5)
  assert_eq(snap.stats_data[0].mean, 3.0)
}

///|
/// Serialize：空统计数据不添加
test "serialize empty stats" {
  let env = @core.new_env(until=10.0)
  let snap = new_snapshot(env)
  snap.add_stats([])
  assert_eq(snap.stats_data.length(), 0)
}

///|
/// Serialize：to_json 输出
test "serialize to_json" {
  let env = @core.new_env(until=100.0)
  let snap = new_snapshot(env)
  let json = snap.to_json()
  assert_true(json.length() > 0)
  assert_true(json.contains("time"))
  assert_true(json.contains("event_count"))
  assert_true(json.contains("processes"))
  assert_true(json.contains("fsms"))
  assert_true(json.contains("stats"))
}

///|
/// Serialize：to_json 含进程和 FSM
test "serialize to_json with data" {
  let env = @core.new_env(until=50.0)
  let p = @process.process(env, name="worker", behavior=fn(_p) {
    @process.Timeout(duration=10.0, next=fn() { @process.Done })
  })
  let sm = @fsm.new_state_machine(initial="A", transitions=[
    @fsm.transition(from="A", to="B", on="go"),
  ])
  ignore(sm.fire("go"))
  let snap = new_snapshot(env)
  snap.add_process(p)
  snap.add_fsm(sm)
  snap.add_stats([1.0, 2.0, 3.0])
  let json = snap.to_json()
  assert_true(json.contains("worker"))
  assert_true(json.contains("current_state"))
  assert_true(json.contains("B"))
  assert_true(json.contains("mean"))
  env.run()
}

///|
/// Serialize：summary 人类可读
test "serialize summary" {
  let env = @core.new_env(until=100.0)
  let snap = new_snapshot(env)
  let s = snap.summary()
  assert_true(s.contains("Simulation Snapshot"))
  assert_true(s.contains("Time:"))
  assert_true(s.contains("Events:"))
}

///|
/// Serialize：完整快照流程
test "serialize full workflow" {
  let env = @core.new_env(until=100.0)
  // 创建进程
  let p1 = @process.process(env, name="p1", behavior=fn(_p) {
    @process.Timeout(duration=10.0, next=fn() { @process.Done })
  })
  let p2 = @process.process(env, name="p2", behavior=fn(_p) {
    @process.Timeout(duration=20.0, next=fn() { @process.Done })
  })
  // 创建 FSM
  let sm = @fsm.new_state_machine(initial="Idle", transitions=[
    @fsm.transition(from="Idle", to="Running", on="start"),
    @fsm.transition(from="Running", to="Done", on="stop"),
  ])
  ignore(sm.fire("start"))
  // 运行
  env.run()
  ignore(sm.fire("stop"))
  // 快照
  let snap = new_snapshot(env)
  snap.add_process(p1)
  snap.add_process(p2)
  snap.add_fsm(sm)
  snap.add_stats([5.0, 10.0, 15.0])
  // 验证
  assert_eq(snap.process_states.length(), 2)
  assert_eq(snap.fsm_states.length(), 1)
  assert_eq(snap.stats_data.length(), 1)
  assert_eq(snap.fsm_states[0].current_state, "Done")
  assert_eq(snap.fsm_states[0].transition_count, 2)
  // JSON
  let json = snap.to_json()
  assert_true(json.contains("p1"))
  assert_true(json.contains("p2"))
  assert_true(json.contains("Done"))
  // summary
  let s = snap.summary()
  assert_true(s.contains("p1"))
  assert_true(s.contains("p2"))
  assert_true(s.contains("Done"))
}
