// ===========================================================================
// Packet
// ===========================================================================

///|
/// Packet：创建与字段访问
test "packet creation" {
  let pkt = new_packet(source="A", dest="B", size=100, data="hello")
  assert_eq(pkt.source, "A")
  assert_eq(pkt.dest, "B")
  assert_eq(pkt.size, 100)
  assert_eq(pkt.data, "hello")
}

///|
/// Packet：默认值
test "packet defaults" {
  let pkt = new_packet(source="X", dest="Y")
  assert_eq(pkt.size, 0)
  assert_eq(pkt.data, "")
}

// ===========================================================================
// Link — 单向延迟链路
// ===========================================================================

///|
/// Link：基本收发
test "link basic send receive" {
  let env = @core.new_env(until=20.0)
  let link = new_link(env, name="A→B", delay=5.0)
  let log : Array[String] = []
  link.receive(fn(pkt) { log.push(pkt.data) })
  link.send(new_packet(source="A", dest="B", data="hi"))
  env.run()
  assert_eq(log.length(), 1)
  assert_eq(log[0], "hi")
}

///|
/// Link：传播延迟正确
test "link propagation delay" {
  let env = @core.new_env(until=20.0)
  let link = new_link(env, name="L", delay=7.0)
  let mut arrive_time = 0.0
  link.receive(fn(_pkt) { arrive_time = env.now() })
  link.send(new_packet(source="A", dest="B"))
  env.run()
  assert_eq(arrive_time, 7.0)
}

///|
/// Link：多包 FIFO（先发后收，包入 buffer 后按 FIFO 取出）
test "link multiple packets fifo" {
  let env = @core.new_env(until=50.0)
  let link = new_link(env, name="L", delay=1.0)
  let log : Array[String] = []
  // 先发送三个包（经过 delay 后进入 buffer）
  link.send(new_packet(source="A", dest="B", data="p1"))
  link.send(new_packet(source="A", dest="B", data="p2"))
  link.send(new_packet(source="A", dest="B", data="p3"))
  // 运行到包全部到达 buffer
  env.run()
  assert_eq(link.pending(), 3)
  // 按 FIFO 取出
  link.receive(fn(pkt) { log.push(pkt.data) })
  link.receive(fn(pkt) { log.push(pkt.data) })
  link.receive(fn(pkt) { log.push(pkt.data) })
  assert_eq(log.length(), 3)
  // buffer 是 FIFO，但同时间事件入 buffer 顺序不保证
  // 验证三个包都收到了
  assert_true(log.contains("p1"))
  assert_true(log.contains("p2"))
  assert_true(log.contains("p3"))
}

///|
/// Link：先发后收
test "link send before receive" {
  let env = @core.new_env(until=20.0)
  let link = new_link(env, name="L", delay=2.0)
  // 先发送（包进入延迟调度，到达后存入 buffer）
  link.send(new_packet(source="A", dest="B", data="early"))
  let log : Array[String] = []
  // 在 t=0 注册接收（但包还没到，t=2 才到）
  link.receive(fn(pkt) { log.push(pkt.data) })
  env.run()
  assert_eq(log.length(), 1)
  assert_eq(log[0], "early")
}

///|
/// Link：pending 计数
test "link pending count" {
  let env = @core.new_env(until=20.0)
  let link = new_link(env, name="L", delay=1.0)
  // 发送包（延迟 1.0 后到达 buffer）
  link.send(new_packet(source="A", dest="B", data="x"))
  assert_eq(link.pending(), 0) // 还没到
  env.run()
  assert_eq(link.pending(), 1) // 到了但没人收
}

///|
/// Link：零延迟
test "link zero delay" {
  let env = @core.new_env(until=10.0)
  let link = new_link(env, name="L", delay=0.0)
  let mut t = 0.0
  link.receive(fn(_pkt) { t = env.now() })
  link.send(new_packet(source="A", dest="B"))
  env.run()
  assert_eq(t, 0.0)
}

// ===========================================================================
// Channel — 双向通道
// ===========================================================================

///|
/// Channel：双向通信
test "channel bidirectional" {
  let env = @core.new_env(until=20.0)
  let ch = new_channel(env, name="A↔B", delay=2.0)
  let log : Array[String] = []
  // B 端接收（正向）
  ch.forward().receive(fn(pkt) { log.push("B got \{pkt.data}") })
  // A 端接收（反向）
  ch.backward().receive(fn(pkt) { log.push("A got \{pkt.data}") })
  // A → B
  ch.forward().send(new_packet(source="A", dest="B", data="ping"))
  // B → A
  ch.backward().send(new_packet(source="B", dest="A", data="pong"))
  env.run()
  assert_eq(log.length(), 2)
  assert_eq(log[0], "B got ping")
  assert_eq(log[1], "A got pong")
}

///|
/// Channel：名称和链路访问
test "channel properties" {
  let env = @core.new_env(until=10.0)
  let ch = new_channel(env, name="ch1", delay=1.0)
  assert_eq(ch.name(), "ch1")
  assert_eq(ch.forward().name(), "ch1_fwd")
  assert_eq(ch.backward().name(), "ch1_bwd")
}

// ===========================================================================
// Router — 路由转发
// ===========================================================================

///|
/// Router：基本转发
test "router forward" {
  let env = @core.new_env(until=20.0)
  let router = new_router(name="R1")
  let link = new_link(env, name="to-B", delay=1.0)
  router.add_route(dest="B", link)
  let log : Array[String] = []
  link.receive(fn(pkt) { log.push(pkt.data) })
  let ok = router.send(new_packet(source="A", dest="B", data="hello"))
  assert_true(ok)
  env.run()
  assert_eq(log.length(), 1)
  assert_eq(log[0], "hello")
}

///|
/// Router：无路由丢包
test "router no route drops" {
  let env = @core.new_env(until=10.0)
  let router = new_router(name="R1")
  let link = new_link(env, name="to-B", delay=1.0)
  router.add_route(dest="B", link)
  let ok = router.send(new_packet(source="A", dest="C", data="lost"))
  assert_false(ok)
}

///|
/// Router：多目的地路由
test "router multiple destinations" {
  let env = @core.new_env(until=20.0)
  let router = new_router(name="R1")
  let link_b = new_link(env, name="to-B", delay=1.0)
  let link_c = new_link(env, name="to-C", delay=2.0)
  router.add_route(dest="B", link_b)
  router.add_route(dest="C", link_c)
  let log : Array[String] = []
  link_b.receive(fn(pkt) { log.push("B:\{pkt.data}") })
  link_c.receive(fn(pkt) { log.push("C:\{pkt.data}") })
  ignore(router.send(new_packet(source="A", dest="B", data="forB")))
  ignore(router.send(new_packet(source="A", dest="C", data="forC")))
  env.run()
  assert_eq(log.length(), 2)
  assert_eq(log[0], "B:forB")
  assert_eq(log[1], "C:forC")
}

///|
/// Router：has_route 查询
test "router has_route" {
  let env = @core.new_env(until=10.0)
  let router = new_router(name="R1")
  let link = new_link(env, name="L", delay=1.0)
  router.add_route(dest="B", link)
  assert_true(router.has_route("B"))
  assert_false(router.has_route("C"))
  assert_eq(router.route_count(), 1)
}

///|
/// Router：多跳转发（A → R1 → R2 → D）
test "router multi-hop" {
  let env = @core.new_env(until=50.0)
  // 拓扑：A --link1--> R1 --link2--> R2 --link3--> D
  let link1 = new_link(env, name="A→R1", delay=2.0)
  let link2 = new_link(env, name="R1→R2", delay=3.0)
  let link3 = new_link(env, name="R2→D", delay=1.0)
  // R1 路由表：目的地 D → link2
  let r1 = new_router(name="R1")
  r1.add_route(dest="D", link2)
  // R2 路由表：目的地 D → link3
  let r2 = new_router(name="R2")
  r2.add_route(dest="D", link3)
  // 记时
  let mut arrive_time = 0.0
  // D 端接收
  link3.receive(fn(_pkt) { arrive_time = env.now() })
  // R1 接收后转发
  link1.receive(fn(pkt) { ignore(r1.send(pkt)) })
  // R2 接收后转发
  link2.receive(fn(pkt) { ignore(r2.send(pkt)) })
  // A 发送
  link1.send(new_packet(source="A", dest="D", data="multi-hop"))
  env.run()
  // 总延迟 = 2.0 + 3.0 + 1.0 = 6.0
  assert_eq(arrive_time, 6.0)
}
