// ===========================================================================
// ProcessGroup — 进程组测试
// ===========================================================================

///|
/// ProcessGroup：基本添加
test "process_group basic add" {
  let env = @core.new_env(until=50.0)
  let group = new_process_group(name="workers")
  let p1 = @process.process(env, name="w1", behavior=fn(_p) {
    @process.Timeout(duration=10.0, next=fn() { @process.Done })
  })
  group.add(p1)
  assert_eq(group.size(), 1)
  assert_eq(group.name(), "workers")
  env.run()
  assert_true(group.is_all_complete())
  assert_eq(group.completed_count(), 1)
  assert_eq(group.pending_count(), 0)
}

///|
/// ProcessGroup：多进程完成跟踪
test "process_group multiple complete" {
  let env = @core.new_env(until=100.0)
  let group = new_process_group(name="batch")
  let p1 = @process.process(env, name="p1", behavior=fn(_p) {
    @process.Timeout(duration=10.0, next=fn() { @process.Done })
  })
  let p2 = @process.process(env, name="p2", behavior=fn(_p) {
    @process.Timeout(duration=20.0, next=fn() { @process.Done })
  })
  let p3 = @process.process(env, name="p3", behavior=fn(_p) {
    @process.Timeout(duration=30.0, next=fn() { @process.Done })
  })
  group.add(p1)
  group.add(p2)
  group.add(p3)
  assert_eq(group.size(), 3)
  assert_eq(group.pending_count(), 3)
  env.run()
  assert_true(group.is_all_complete())
  assert_eq(group.completed_count(), 3)
}

///|
/// ProcessGroup：on_all_complete 回调
test "process_group on_all_complete" {
  let env = @core.new_env(until=100.0)
  let group = new_process_group(name="workers")
  let mut all_done = false
  let p1 = @process.process(env, name="p1", behavior=fn(_p) {
    @process.Timeout(duration=10.0, next=fn() { @process.Done })
  })
  let p2 = @process.process(env, name="p2", behavior=fn(_p) {
    @process.Timeout(duration=20.0, next=fn() { @process.Done })
  })
  group.add(p1)
  group.add(p2)
  group.on_all_complete(fn() { all_done = true })
  assert_false(all_done)
  env.run()
  assert_true(all_done)
  assert_true(group.is_all_complete())
}

///|
/// ProcessGroup：空组
test "process_group empty" {
  let group = new_process_group(name="empty")
  assert_eq(group.size(), 0)
  assert_eq(group.completed_count(), 0)
  assert_false(group.is_all_complete())
}

///|
/// ProcessGroup：逐个完成
test "process_group sequential complete" {
  let env = @core.new_env(until=100.0)
  let group = new_process_group(name="seq")
  let log : Array[String] = []
  let p1 = @process.process(env, name="p1", behavior=fn(_p) {
    @process.Timeout(duration=10.0, next=fn() { @process.Done })
  })
  let p2 = @process.process(env, name="p2", behavior=fn(_p) {
    @process.Timeout(duration=30.0, next=fn() { @process.Done })
  })
  group.add(p1)
  group.add(p2)
  group.on_all_complete(fn() { log.push("all done") })
  env.run()
  assert_eq(group.completed_count(), 2)
  assert_eq(log.length(), 1)
}

///|
/// ProcessGroup：进程状态查询
test "process_group member access" {
  let env = @core.new_env(until=50.0)
  let group = new_process_group(name="workers")
  let p1 = @process.process(env, name="w1", behavior=fn(_p) {
    @process.Timeout(duration=10.0, next=fn() { @process.Done })
  })
  let p2 = @process.process(env, name="w2", behavior=fn(_p) {
    @process.Timeout(duration=20.0, next=fn() { @process.Done })
  })
  group.add(p1)
  group.add(p2)
  assert_eq(group.get(0).name(), "w1")
  assert_eq(group.get(1).name(), "w2")
  let members = group.members()
  assert_eq(members.length(), 2)
  env.run()
}

///|
/// ProcessGroup：单进程
test "process_group single process" {
  let env = @core.new_env(until=50.0)
  let group = new_process_group(name="single")
  let p = @process.process(env, name="solo", behavior=fn(_p) {
    @process.Timeout(duration=5.0, next=fn() { @process.Done })
  })
  group.add(p)
  assert_false(group.is_all_complete())
  env.run()
  assert_true(group.is_all_complete())
  assert_eq(group.completed_count(), 1)
}

///|
/// ProcessGroup：已完成进程添加
test "process_group add completed process" {
  let env = @core.new_env(until=50.0)
  let group = new_process_group(name="test")
  let p = @process.process(env, name="done", behavior=fn(_p) { @process.Done })
  env.run()
  // p 已完成
  group.add(p)
  assert_eq(group.completed_count(), 1)
  assert_true(group.is_all_complete())
}
