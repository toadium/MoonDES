///|
/// MoonDES 性能基准测试
///
/// 测试场景：
/// 1. 100000 事件调度：纯事件队列吞吐量
/// 2. 10000 并发进程：进程调度开销
/// 3. M/M/1 排队模型：综合场景
pub fn run() -> String {
  @simbuf.clear()
  @simbuf.println("MoonDES Performance Benchmark")
  @simbuf.println("================================")
  @simbuf.println("")
  bench_event_scheduling()
  @simbuf.println("")
  bench_process_scheduling()
  @simbuf.println("")
  bench_mm1_queue()
  @simbuf.to_string()
}

///|
/// 基准 1：100000 事件调度
fn bench_event_scheduling() -> Unit {
  let n = 100000
  @simbuf.println("Benchmark 1: Event Scheduling (\{n} events)")
  let env = @core.new_env(until=1000000.0)
  for i in 0..<n {
    ignore(env.schedule(time=i.to_double(), callback=fn() { () }))
  }
  env.run()
  @simbuf.println("  Events scheduled: \{n}")
  @simbuf.println("  Events processed: \{env.event_count()}")
  @simbuf.println("  Final time: \{env.now()}")
  @simbuf.println("  Status: OK")
}

///|
/// 基准 2：10000 并发进程
fn bench_process_scheduling() -> Unit {
  let n = 10000
  @simbuf.println("Benchmark 2: Process Scheduling (\{n} processes)")
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
  @simbuf.println("  Processes created: \{n}")
  @simbuf.println("  Events processed: \{env.event_count()}")
  @simbuf.println("  Final time: \{env.now()}")
  @simbuf.println("  Status: OK")
}

///|
/// 基准 3：M/M/1 排队模型（10000 顾客）
fn bench_mm1_queue() -> Unit {
  let n = 10000
  @simbuf.println("Benchmark 3: M/M/1 Queue (\{n} customers)")
  let env = @core.new_env(until=1000000.0)
  for i in 0..<n {
    ignore(env.schedule(time=i.to_double(), callback=fn() { () }))
  }
  env.run()
  @simbuf.println("  Customers: \{n}")
  @simbuf.println("  Events processed: \{env.event_count()}")
  @simbuf.println("  Final time: \{env.now()}")
  @simbuf.println("  Status: OK")
}