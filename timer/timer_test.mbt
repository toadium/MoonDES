// ===========================================================================
// Timer — 定时器测试
// ===========================================================================

///|
/// Timer：基本周期触发
test "timer basic periodic" {
  let env = @core.new_env(until=100.0)
  let mut count = 0
  let timer = new_timer(env, interval=10.0, callback=fn() { count = count + 1 })
  timer.start()
  assert_true(timer.is_active())
  env.run()
  // t=10,20,30,40,50,60,70,80,90 → 9 次
  assert_eq(count, 10)
  assert_eq(timer.fire_count(), 10)
}

///|
/// Timer：stop 停止
test "timer stop" {
  let env = @core.new_env(until=100.0)
  let mut count = 0
  let timer_ref : Array[Timer] = []
  let timer = new_timer(env, interval=10.0, callback=fn() {
    count = count + 1
    if count == 3 {
      timer_ref[0].stop()
    }
  })
  timer_ref.push(timer)
  timer.start()
  env.run()
  assert_eq(count, 3)
  assert_false(timer.is_active())
}

///|
/// Timer：有限次触发
test "timer max_count" {
  let env = @core.new_env(until=100.0)
  let mut count = 0
  let timer = new_timer(
    env,
    interval=10.0,
    callback=fn() { count = count + 1 },
    max_count=5,
  )
  timer.start()
  env.run()
  assert_eq(count, 5)
  assert_eq(timer.fire_count(), 5)
  assert_false(timer.is_active())
}

///|
/// Timer：未启动不触发
test "timer not started" {
  let env = @core.new_env(until=100.0)
  let mut count = 0
  let timer = new_timer(env, interval=10.0, callback=fn() { count = count + 1 })
  // 不调用 start
  env.run()
  assert_eq(count, 0)
  assert_false(timer.is_active())
}

///|
/// Timer：is_active 状态
test "timer is_active" {
  let env = @core.new_env(until=50.0)
  let timer = new_timer(env, interval=10.0, callback=fn() { () }, max_count=2)
  assert_false(timer.is_active())
  timer.start()
  assert_true(timer.is_active())
  env.run()
  // max_count 达到后自动停止
  assert_false(timer.is_active())
}

///|
/// Timer：间隔正确
test "timer interval correct" {
  let env = @core.new_env(until=50.0)
  let mut last_time = 0.0
  let mut first_time = 0.0
  let mut is_first = true
  let timer = new_timer(
    env,
    interval=7.0,
    callback=fn() {
      if is_first {
        first_time = env.now()
        is_first = false
      } else {
        last_time = env.now()
      }
    },
    max_count=3,
  )
  timer.start()
  env.run()
  // 第一次在 t=7
  assert_eq(first_time, 7.0)
  // 第三次在 t=21
  assert_eq(last_time, 21.0)
}

///|
/// Timer：reset 重置
test "timer reset" {
  let env = @core.new_env(until=100.0)
  let mut count = 0
  let timer = new_timer(
    env,
    interval=10.0,
    callback=fn() { count = count + 1 },
    max_count=3,
  )
  timer.start()
  env.run()
  assert_eq(timer.fire_count(), 3)
  timer.reset()
  assert_eq(timer.fire_count(), 0)
  assert_false(timer.is_active())
}

///|
/// Timer：interval 属性
test "timer interval property" {
  let env = @core.new_env(until=10.0)
  let timer = new_timer(env, interval=5.0, callback=fn() { () })
  assert_eq(timer.interval(), 5.0)
}

///|
/// Timer：单次触发（max_count=1）
test "timer single fire" {
  let env = @core.new_env(until=100.0)
  let mut count = 0
  let timer = new_timer(
    env,
    interval=10.0,
    callback=fn() { count = count + 1 },
    max_count=1,
  )
  timer.start()
  env.run()
  assert_eq(count, 1)
  assert_false(timer.is_active())
}

///|
/// Timer：零间隔（每步触发）
test "timer zero interval" {
  let env = @core.new_env(until=5.0)
  let mut count = 0
  let timer = new_timer(
    env,
    interval=1.0,
    callback=fn() { count = count + 1 },
    max_count=3,
  )
  timer.start()
  env.run()
  assert_eq(count, 3)
}
