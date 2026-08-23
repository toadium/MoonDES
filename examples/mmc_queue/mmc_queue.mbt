///|
/// 示例：M/M/c 排队系统
///
/// c 个服务台，顾客按指数分布到达（率 λ），服务时间指数分布（率 μ）。
/// 统计：系统吞吐量、平均等待时间、平均队列长度、服务台利用率。
/// 使用 Resource 层的 Capacity 资源模拟 c 个服务台。
///
/// 运行：moon run ./examples/mmc_queue --target wasm
fn main {
  let c = 3 // 服务台数量
  let lambda = 0.5 // 到达率
  let mu = 0.3 // 服务率
  let until = 200.0 // 仿真时长

  let env = @core.new_env(until~)
  let rng = @random.new_rng()
  let pool = @resource.new_capacity(name="servers", capacity=c)

  let mut served = 0
  let mut total_wait = 0.0
  let mut total_system_time = 0.0
  let mut max_queue = 0
  let mut current_in_system = 0
  let wait_times : Array[Double] = []

  // 到达进程
  ignore(
    @process.process(env, name="arrival", behavior=fn(p) {
      let arrive_time = env.now()
      current_in_system = current_in_system + 1
      if current_in_system > max_queue {
        max_queue = current_in_system
      }
      // 请求服务台
      ignore(
        pool.request(pid=p.id(), callback=fn() {
          let wait = env.now() - arrive_time
          total_wait = total_wait + wait
          wait_times.push(wait)
          // 服务时间 ~ Exp(mu)
          let service_time = @random.exponential(rng, lambda=mu)
          ignore(
            env.schedule(time=env.now() + service_time, callback=fn() {
              let sys_time = env.now() - arrive_time
              total_system_time = total_system_time + sys_time
              served = served + 1
              current_in_system = current_in_system - 1
              pool.release()
            }),
          )
        }),
      )
      // 下一个到达 ~ Exp(lambda)
      let inter_arrival = @random.exponential(rng, lambda~)
      @process.Timeout(duration=inter_arrival, next=fn() {
        let arrive2 = env.now()
        current_in_system = current_in_system + 1
        if current_in_system > max_queue {
          max_queue = current_in_system
        }
        ignore(
          pool.request(pid=p.id(), callback=fn() {
            let wait2 = env.now() - arrive2
            total_wait = total_wait + wait2
            wait_times.push(wait2)
            let svc2 = @random.exponential(rng, lambda=mu)
            ignore(
              env.schedule(time=env.now() + svc2, callback=fn() {
                let sys2 = env.now() - arrive2
                total_system_time = total_system_time + sys2
                served = served + 1
                current_in_system = current_in_system - 1
                pool.release()
              }),
            )
          }),
        )
        let next_ia = @random.exponential(rng, lambda~)
        @process.Timeout(duration=next_ia, next=fn() {
          let arrive3 = env.now()
          current_in_system = current_in_system + 1
          if current_in_system > max_queue {
            max_queue = current_in_system
          }
          ignore(
            pool.request(pid=p.id(), callback=fn() {
              let wait3 = env.now() - arrive3
              total_wait = total_wait + wait3
              wait_times.push(wait3)
              let svc3 = @random.exponential(rng, lambda=mu)
              ignore(
                env.schedule(time=env.now() + svc3, callback=fn() {
                  let sys3 = env.now() - arrive3
                  total_system_time = total_system_time + sys3
                  served = served + 1
                  current_in_system = current_in_system - 1
                  pool.release()
                }),
              )
            }),
          )
          @process.Done
        })
      })
    }),
  )

  env.run()

  // 理论值：利用度 ρ = λ/(cμ)
  let rho = lambda / (c.to_double() * mu)
  // 理论平均等待时间（M/M/c Erlang-C 公式简化）
  let avg_wait = if served > 0 { total_wait / served.to_double() } else { 0.0 }
  let avg_sys = if served > 0 {
    total_system_time / served.to_double()
  } else {
    0.0
  }
  let throughput = served.to_double() / env.now()

  println("M/M/c Queue Simulation")
  println("======================")
  println("Parameters:")
  println("  Servers (c):     \{c}")
  println("  Arrival rate (λ): \{lambda}")
  println("  Service rate (μ): \{mu}")
  println("  Simulation time:  \{until}")
  println("")
  println("Results:")
  println("  Customers served:   \{served}")
  println("  Throughput:         \{throughput}")
  println("  Avg wait time:      \{avg_wait}")
  println("  Avg system time:    \{avg_sys}")
  println("  Max queue length:   \{max_queue}")
  println("  Utilization (ρ):    \{rho}")
  println("")
  if wait_times.length() > 0 {
    let ws = @stats.summary(wait_times)
    println("Wait time statistics:")
    println("  Mean:   \{ws.mean}")
    println("  StdDev: \{ws.stddev}")
    println("  Min:    \{ws.min}")
    println("  Max:    \{ws.max}")
  }
  println("")
  println("Events processed: \{env.event_count()}")
}
