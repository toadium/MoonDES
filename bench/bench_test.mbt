///|
/// 基准测试套件
///
/// 用 `moon test` 运行，验证大规模场景的正确性和性能特征。
/// 不测量墙钟时间（Wasm 沙箱不稳定），而是验证事件/进程/资源
/// 在规模下的正确性，并记录事件计数作为吞吐量指标。

// ===========================================================================
// 事件吞吐量
// ===========================================================================

///|
/// 10000 事件调度正确性
test "bench: 10k event scheduling" {
  let env = @core.new_env(until=100000.0)
  let mut count = 0
  for i in 0..<10000 {
    ignore(
      env.schedule(time=i.to_double(), callback=fn() { count = count + 1 }),
    )
  }
  env.run()
  assert_eq(count, 10000)
  assert_eq(env.event_count(), 10000)
}

///|
/// 50000 事件调度正确性
test "bench: 50k event scheduling" {
  let env = @core.new_env(until=1000000.0)
  let mut count = 0
  for i in 0..<50000 {
    ignore(
      env.schedule(time=i.to_double() * 2.0, callback=fn() { count = count + 1 }),
    )
  }
  env.run()
  assert_eq(count, 50000)
}

// ===========================================================================
// 进程扩展性
// ===========================================================================

///|
/// 100 并发进程各自完成
test "bench: 100 concurrent processes" {
  let env = @core.new_env(until=1000.0)
  let mut completed = 0
  for i in 0..<100 {
    let delay = i.to_double() * 0.1 + 1.0
    ignore(
      @process.process(env, name="p\{i}", behavior=fn(_) {
        @process.Timeout(duration=delay, next=fn() {
          completed = completed + 1
          @process.Done
        })
      }),
    )
  }
  env.run()
  assert_eq(completed, 100)
}

///|
/// 500 进程链式 Timeout
test "bench: 500 process chain" {
  let env = @core.new_env(until=10000.0)
  let mut final_count = 0
  for _ in 0..<500 {
    ignore(
      @process.process(env, behavior=fn(_) {
        @process.Timeout(duration=1.0, next=fn() {
          @process.Timeout(duration=2.0, next=fn() {
            @process.Timeout(duration=3.0, next=fn() {
              final_count = final_count + 1
              @process.Done
            })
          })
        })
      }),
    )
  }
  env.run()
  assert_eq(final_count, 500)
}

// ===========================================================================
// 资源竞争
// ===========================================================================

///|
/// 50 进程竞争 1 个独占资源
test "bench: 50 processes 1 exclusive resource" {
  let env = @core.new_env(until=10000.0)
  let server = @resource.new_exclusive(name="server")
  let mut served = 0
  for i in 0..<50 {
    ignore(
      @process.process(env, name="client\{i}", behavior=fn(p) {
        ignore(
          server.request(pid=p.id(), callback=fn() {
            served = served + 1
            server.release()
          }),
        )
        @process.Done
      }),
    )
  }
  env.run()
  assert_eq(served, 50)
}

///|
/// 100 进程竞争 Capacity(5) 资源
test "bench: 100 processes capacity-5 resource" {
  let env = @core.new_env(until=10000.0)
  let pool = @resource.new_capacity(name="pool", capacity=5)
  let mut served = 0
  for i in 0..<100 {
    ignore(
      @process.process(env, name="worker\{i}", behavior=fn(p) {
        ignore(
          pool.request(pid=p.id(), callback=fn() {
            served = served + 1
            pool.release()
          }),
        )
        @process.Done
      }),
    )
  }
  env.run()
  assert_eq(served, 100)
}

// ===========================================================================
// 同步原语规模
// ===========================================================================

///|
/// 100 次 Semaphore acquire/release
test "bench: semaphore 100 acquire release" {
  let env = @core.new_env(until=10000.0)
  let sem = @sync.new_semaphore(count=1)
  let mut count = 0
  for i in 0..<100 {
    ignore(
      @process.process(env, name="t\{i}", behavior=fn(_) {
        sem.acquire(fn() {
          count = count + 1
          sem.release()
        })
        @process.Done
      }),
    )
  }
  env.run()
  assert_eq(count, 100)
}

///|
/// Store 1000 put/get
test "bench: store 1000 put get" {
  let store : @sync.Store[Int] = @sync.new_store()
  let mut sum = 0
  for i in 0..<1000 {
    store.put(i)
  }
  for _ in 0..<1000 {
    store.get(fn(item) { sum = sum + item })
  }
  assert_eq(store.size(), 0)
  // sum = 0+1+...+999 = 999*1000/2 = 499500
  assert_eq(sum, 499500)
}

///|
/// Barrier 20 进程同步
test "bench: barrier 20 processes" {
  let env = @core.new_env(until=1000.0)
  let barrier = @sync.new_barrier(n=20)
  let mut passed = 0
  for i in 0..<20 {
    ignore(
      @process.process(env, name="w\{i}", behavior=fn(_) {
        barrier.wait(fn() { passed = passed + 1 })
        @process.Done
      }),
    )
  }
  env.run()
  assert_eq(passed, 20)
  assert_true(barrier.is_reset())
}

///|
/// Container 连续资源 put/get
test "bench: container put get" {
  let tank = @sync.new_container_with(capacity=100.0, initial=0.0)
  let mut filled = 0
  // 填充
  for _ in 0..<10 {
    tank.put(10.0, fn() { filled = filled + 1 })
  }
  assert_eq(filled, 10)
  assert_eq(tank.level(), 100.0)
  // 取出
  let mut drained = 0
  for _ in 0..<10 {
    tank.get(10.0, fn() { drained = drained + 1 })
  }
  assert_eq(drained, 10)
  assert_eq(tank.level(), 0.0)
}
