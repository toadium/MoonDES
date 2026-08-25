///|
/// 示例：传感器网络仿真
///
/// 3 个传感器节点定期采集数据并发布到事件总线：
///   - temp_sensor  → "temperature" 主题
///   - humid_sensor → "humidity" 主题
///   - press_sensor → "pressure" 主题
///
/// 监控中心订阅所有主题，统计接收数据量。
/// 告警系统订阅 temperature，超过阈值时告警。
///
/// 运行：moon run ./examples/sensor_network --target wasm
fn main {
  let env = @core.new_env(until=100.0)
  let rng = @random.new_rng()
  let bus = @eventbus.new_event_bus()

  // 统计
  let mut total_readings = 0
  let mut alerts = 0
  let mut temp_readings = 0
  let mut humid_readings = 0
  let mut press_readings = 0

  // 监控中心：订阅所有主题
  ignore(
    bus.subscribe("temperature", fn(_data) {
      total_readings = total_readings + 1
      temp_readings = temp_readings + 1
    }),
  )
  ignore(
    bus.subscribe("humidity", fn(_data) {
      total_readings = total_readings + 1
      humid_readings = humid_readings + 1
    }),
  )
  ignore(
    bus.subscribe("pressure", fn(_data) {
      total_readings = total_readings + 1
      press_readings = press_readings + 1
    }),
  )

  // 告警系统：订阅 temperature，超阈值告警
  ignore(
    bus.subscribe("temperature", fn(_data) {
      // 简单解析：data 格式 "temp=XX.X"
      // 这里用随机模拟告警
      let r = @random.uniform(rng, min=0.0, max=1.0)
      if r < 0.1 {
        alerts = alerts + 1
      }
    }),
  )

  // 温度传感器进程
  ignore(
    @process.process(env, name="temp_sensor", behavior=fn(_p) {
      let temp = 20.0 + @random.normal(rng, mean=0.0, std=5.0)
      ignore(bus.publish("temperature", "temp=\{temp}"))
      let interval = @random.exponential(rng, lambda=0.5)
      @process.Timeout(duration=interval, next=fn() {
        let temp2 = 20.0 + @random.normal(rng, mean=0.0, std=5.0)
        ignore(bus.publish("temperature", "temp=\{temp2}"))
        let interval2 = @random.exponential(rng, lambda=0.5)
        @process.Timeout(duration=interval2, next=fn() {
          let temp3 = 20.0 + @random.normal(rng, mean=0.0, std=5.0)
          ignore(bus.publish("temperature", "temp=\{temp3}"))
          @process.Done
        })
      })
    }),
  )

  // 湿度传感器进程
  ignore(
    @process.process(env, name="humid_sensor", behavior=fn(_p) {
      let humid = 50.0 + @random.normal(rng, mean=0.0, std=10.0)
      ignore(bus.publish("humidity", "humid=\{humid}"))
      let interval = @random.exponential(rng, lambda=0.3)
      @process.Timeout(duration=interval, next=fn() {
        let humid2 = 50.0 + @random.normal(rng, mean=0.0, std=10.0)
        ignore(bus.publish("humidity", "humid=\{humid2}"))
        let interval2 = @random.exponential(rng, lambda=0.3)
        @process.Timeout(duration=interval2, next=fn() {
          let humid3 = 50.0 + @random.normal(rng, mean=0.0, std=10.0)
          ignore(bus.publish("humidity", "humid=\{humid3}"))
          @process.Done
        })
      })
    }),
  )

  // 压力传感器进程
  ignore(
    @process.process(env, name="press_sensor", behavior=fn(_p) {
      let press = 101.3 + @random.normal(rng, mean=0.0, std=2.0)
      ignore(bus.publish("pressure", "press=\{press}"))
      let interval = @random.exponential(rng, lambda=0.4)
      @process.Timeout(duration=interval, next=fn() {
        let press2 = 101.3 + @random.normal(rng, mean=0.0, std=2.0)
        ignore(bus.publish("pressure", "press=\{press2}"))
        let interval2 = @random.exponential(rng, lambda=0.4)
        @process.Timeout(duration=interval2, next=fn() {
          let press3 = 101.3 + @random.normal(rng, mean=0.0, std=2.0)
          ignore(bus.publish("pressure", "press=\{press3}"))
          @process.Done
        })
      })
    }),
  )

  env.run()

  println("Sensor Network Simulation")
  println("==========================")
  println("Simulation time: \{env.now()}")
  println("Events processed: \{env.event_count()}")
  println("")
  println("Event Bus Topics: {bus.topics().length()}")
  println("Total subscribers: \{bus.total_subscribers()}")
  println("")
  println("Results:")
  println("  Total readings:     \{total_readings}")
  println("  Temperature readings: \{temp_readings}")
  println("  Humidity readings:    \{humid_readings}")
  println("  Pressure readings:    \{press_readings}")
  println("  Alerts triggered:     \{alerts}")
  println("")
  println("Subscriber counts:")
  println("  temperature: \{bus.subscriber_count("temperature")}")
  println("  humidity:    \{bus.subscriber_count("humidity")}")
  println("  pressure:    \{bus.subscriber_count("pressure")}")
}
