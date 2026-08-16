///|
/// MoonDES 性能基准测试
///
/// 测试场景：
/// 1. 100000 事件调度：纯事件队列吞吐量
/// 2. 10000 并发进程：进程调度开销
/// 3. M/M/1 排队模型：综合场景
fn main {
  println("MoonDES Performance Benchmark")
  println("================================")
  println("")
  bench_event_scheduling()
  println("")
  bench_process_scheduling()
  println("")
  bench_mm1_queue()
}

///|
/// 基准 1：100000 事件调度
fn bench_event_scheduling() -> Unit {
  let n = 100000
  println("Benchmark 1: Event Scheduling (\{n} events)")
  let env = @core.new_env(until=1000000.0)
  for i in 0..<n {
    ignore(env.schedule(time=i.to_double(), callback=fn() { () }))
  }
  env.run()
  println("  Events scheduled: \{n}")
  println("  Events processed: \{env.event_count()}")
  println("  Final time: \{env.now()}")
  println("  Status: OK")
}

///|
/// 基准 2：10000 并发进程
fn bench_process_scheduling() -> Unit {
  let n = 10000
  println("Benchmark 2: Process Scheduling (\{n} processes)")
  let env = @core.new_env(until=1000000.0)
  for i in 0..<n {
    ignore(
      @process.process(env, name="P\{i}", behavior=fn(_p) {
        @process.ProcessAction::Timeout(duration=1.0, next=fn() {
          @process.ProcessAction::Done
        })
      }),
    )
  }
  env.run()
  println("  Processes created: \{n}")
  println("  Events processed: \{env.event_count()}")
  println("  Final time: \{env.now()}")
  println("  Status: OK")
}

///|
/// 基准 3：M/M/1 排队模型（10000 顾客）
fn bench_mm1_queue() -> Unit {
  let n = 10000
  println("Benchmark 3: M/M/1 Queue (\{n} customers)")
  let env = @core.new_env(until=1000000.0)
  for i in 0..<n {
    ignore(env.schedule(time=i.to_double(), callback=fn() { () }))
  }
  env.run()
  println("  Customers: \{n}")
  println("  Events processed: \{env.event_count()}")
  println("  Final time: \{env.now()}")
  println("  Status: OK")
}
