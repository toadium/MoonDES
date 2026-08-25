///|
/// interrupt：中断挂起的 Timeout 进程
test "process interrupt timeout" {
  let env = @core.new_env(until=20.0)
  let log : Array[String] = []
  let p = @process.process(env, name="worker", behavior=fn(_) {
    @process.Timeout(duration=10.0, next=fn() {
      log.push("resumed")
      @process.Done
    })
  })
  // 在 t=2 中断
  ignore(
    @process.process(env, name="interrupter", behavior=fn(_) {
      @process.Timeout(duration=2.0, next=fn() {
        p.interrupt()
        log.push("interrupted at \{env.now()}")
        @process.Done
      })
    }),
  )
  env.run()
  assert_eq(log.length(), 1)
  assert_true(log[0].contains("interrupted"))
  assert_false(p.is_alive())
  assert_true(p.is_interrupted())
}

///|
/// interrupt：对已终止进程无效果
test "process interrupt terminated no effect" {
  let env = @core.new_env(until=10.0)
  let p = @process.process(env, name="quick", behavior=fn(_) { @process.Done })
  env.run()
  assert_false(p.is_alive())
  p.interrupt()
  assert_false(p.is_interrupted())
}

///|
/// interrupt：未中断的进程正常恢复
test "process not interrupted resumes normally" {
  let env = @core.new_env(until=20.0)
  let log : Array[String] = []
  let p = @process.process(env, name="worker", behavior=fn(_) {
    @process.Timeout(duration=5.0, next=fn() {
      log.push("resumed")
      @process.Done
    })
  })
  env.run()
  assert_eq(log.length(), 1)
  assert_false(p.is_interrupted())
  assert_false(p.is_alive())
}

///|
/// on_complete：进程正常完成时触发
test "process on_complete normal" {
  let env = @core.new_env(until=10.0)
  let log : Array[String] = []
  let p = @process.process(env, name="worker", behavior=fn(_) {
    @process.Timeout(duration=3.0, next=fn() { @process.Done })
  })
  p.on_complete(fn() { log.push("done") })
  env.run()
  assert_eq(log.length(), 1)
  assert_eq(log[0], "done")
}

///|
/// on_complete：对已完成进程立即调用
test "process on_complete already finished" {
  let env = @core.new_env(until=10.0)
  let log : Array[String] = []
  let p = @process.process(env, name="quick", behavior=fn(_) { @process.Done })
  env.run()
  p.on_complete(fn() { log.push("late") })
  assert_eq(log.length(), 1)
}

///|
/// on_complete：中断时也触发
test "process on_complete on interrupt" {
  let env = @core.new_env(until=20.0)
  let log : Array[String] = []
  let p = @process.process(env, name="worker", behavior=fn(_) {
    @process.Timeout(duration=10.0, next=fn() { @process.Done })
  })
  p.on_complete(fn() { log.push("completed") })
  ignore(
    @process.process(env, name="interrupter", behavior=fn(_) {
      @process.Timeout(duration=2.0, next=fn() {
        p.interrupt()
        @process.Done
      })
    }),
  )
  env.run()
  assert_eq(log.length(), 1)
  assert_eq(log[0], "completed")
}

///|
/// on_complete：多个回调按注册顺序触发
test "process on_complete multiple callbacks" {
  let env = @core.new_env(until=10.0)
  let log : Array[Int] = []
  let p = @process.process(env, name="worker", behavior=fn(_) {
    @process.Timeout(duration=1.0, next=fn() { @process.Done })
  })
  p.on_complete(fn() { log.push(1) })
  p.on_complete(fn() { log.push(2) })
  p.on_complete(fn() { log.push(3) })
  env.run()
  assert_eq(log.length(), 3)
  assert_eq(log[0], 1)
  assert_eq(log[1], 2)
  assert_eq(log[2], 3)
}

///|
/// status：获取进程状态
test "process status query" {
  let env = @core.new_env(until=10.0)
  let p = @process.process(env, name="worker", behavior=fn(_) {
    @process.Timeout(duration=5.0, next=fn() { @process.Done })
  })
  env.run()
  assert_eq(p.status(), @process.Terminated)
}

///|
/// join：一个进程等待另一个进程完成
test "process join pattern" {
  let env = @core.new_env(until=20.0)
  let log : Array[String] = []
  let worker = @process.process(env, name="worker", behavior=fn(_) {
    @process.Timeout(duration=5.0, next=fn() {
      log.push("worker done at \{env.now()}")
      @process.Done
    })
  })
  ignore(
    @process.process(env, name="waiter", behavior=fn(_) {
      @process.Timeout(duration=1.0, next=fn() {
        worker.on_complete(fn() { log.push("waiter notified at \{env.now()}") })
        @process.Done
      })
    }),
  )
  env.run()
  assert_eq(log.length(), 2)
  assert_true(log[0].contains("worker done"))
  assert_true(log[1].contains("waiter notified"))
}
