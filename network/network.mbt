///|
/// 数据包
///
/// 网络传输的基本单元，包含源/目的地址、大小和负载数据。
///
/// # Example
/// ```mbt check
/// test {
///   let pkt = @network.new_packet(source="A", dest="B", size=100, data="hello")
///   inspect(pkt.source, content="A")
///   inspect(pkt.dest, content="B")
///   inspect(pkt.size, content="100")
/// }
/// ```
pub(all) struct Packet {
  source : String
  dest : String
  size : Int
  data : String
}

///|
/// 创建数据包
pub fn new_packet(
  source~ : String,
  dest~ : String,
  size? : Int = 0,
  data? : String = "",
) -> Packet {
  { source, dest, size, data }
}

// ---------------------------------------------------------------------------
// Link — 单向延迟链路
// ---------------------------------------------------------------------------

///|
/// 单向延迟链路
///
/// 模拟从源端到目的端的物理链路，具有传播延迟 `delay`。
/// 发送端调用 `send(packet)`，数据包经过延迟后到达接收端缓冲区。
/// 接收端调用 `receive(callback)` 从缓冲区取出数据包，缓冲区空时阻塞。
///
/// 内部使用 `Store[Packet]` 作为接收缓冲区，`env.schedule` 实现延迟投递。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=20.0)
///   let link = @network.new_link(env, name="A→B", delay=5.0)
///   let log : Array[String] = []
///   link.receive(fn(pkt) { log.push("got \{pkt.data} at \{env.now()}") })
///   link.send(@network.new_packet(source="A", dest="B", data="hi"))
///   env.run()
///   assert_eq(log.length(), 1)
///   assert_true(log[0].contains("at 5")) // 延迟 5.0 后到达
/// }
/// ```
pub(all) struct Link {
  name : String
  delay : Double
  env : @core.SimulationEnv
  buffer : @sync.Store[Packet]
}

///|
/// 创建单向延迟链路
///
/// - `delay`：传播延迟（仿真时间单位）
pub fn new_link(
  env : @core.SimulationEnv,
  name~ : String,
  delay~ : Double,
) -> Link {
  { name, delay, env, buffer: @sync.new_store() }
}

///|
/// 发送数据包
///
/// 数据包经过 `delay` 延迟后到达接收端缓冲区。
pub fn Link::send(self : Link, packet : Packet) -> Unit {
  let buffer = self.buffer
  let arrive_time = self.env.now() + self.delay
  ignore(
    self.env.schedule(time=arrive_time, callback=fn() { buffer.put(packet) }),
  )
}

///|
/// 接收数据包
///
/// 从接收缓冲区取出数据包。缓冲区空时阻塞等待。
pub fn Link::receive(self : Link, callback : (Packet) -> Unit) -> Unit {
  self.buffer.get(callback)
}

///|
/// 缓冲区中待接收的数据包数量
pub fn Link::pending(self : Link) -> Int {
  self.buffer.size()
}

///|
/// 链路名称
pub fn Link::name(self : Link) -> String {
  self.name
}

// ---------------------------------------------------------------------------
// Channel — 双向通道
// ---------------------------------------------------------------------------

///|
/// 双向通道
///
/// 由两条单向链路组成，实现双端通信。
/// `forward`：A → B 方向，`backward`：B → A 方向。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=20.0)
///   let ch = @network.new_channel(env, name="A↔B", delay=2.0)
///   let log : Array[String] = []
///   // B 端接收
///   ch.forward().receive(fn(pkt) { log.push("B got \{pkt.data}") })
///   // A 端发送
///   ch.forward().send(@network.new_packet(source="A", dest="B", data="ping"))
///   env.run()
///   assert_eq(log.length(), 1)
/// }
/// ```
pub(all) struct Channel {
  name : String
  fwd : Link
  bwd : Link
}

///|
/// 创建双向通道
///
/// 两个方向共享相同的传播延迟 `delay`。
pub fn new_channel(
  env : @core.SimulationEnv,
  name~ : String,
  delay~ : Double,
) -> Channel {
  {
    name,
    fwd: new_link(env, name=name + "_fwd", delay~),
    bwd: new_link(env, name=name + "_bwd", delay~),
  }
}

///|
/// 正向链路（A → B）
pub fn Channel::forward(self : Channel) -> Link {
  self.fwd
}

///|
/// 反向链路（B → A）
pub fn Channel::backward(self : Channel) -> Link {
  self.bwd
}

///|
/// 通道名称
pub fn Channel::name(self : Channel) -> String {
  self.name
}

// ---------------------------------------------------------------------------
// Router — 路由表转发
// ---------------------------------------------------------------------------

///|
/// 简单路由器
///
/// 维护目的地址到下一跳链路的路由表。
/// `send(packet)` 查找目的地址对应的链路并转发；
/// 无匹配路由时丢弃数据包并返回 `false`。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=20.0)
///   let router = @network.new_router(name="R1")
///   let link = @network.new_link(env, name="to-B", delay=1.0)
///   router.add_route(dest="B", link)
///   let ok = router.send(@network.new_packet(source="A", dest="B", data="hi"))
///   assert_true(ok)
///   let dropped = router.send(
///     @network.new_packet(source="A", dest="C", data="hi"),
///   )
///   assert_false(dropped)
/// }
/// ```
pub(all) struct Router {
  name : String
  routes : Map[String, Link]
}

///|
/// 创建路由器
pub fn new_router(name~ : String) -> Router {
  { name, routes: {} }
}

///|
/// 添加路由规则
///
/// 将目的地址 `dest` 映射到下一跳链路 `link`。
pub fn Router::add_route(self : Router, dest~ : String, link : Link) -> Unit {
  self.routes[dest] = link
}

///|
/// 转发数据包
///
/// 查找路由表，找到匹配的链路则转发并返回 `true`，
/// 无匹配路由则丢弃并返回 `false`。
pub fn Router::send(self : Router, packet : Packet) -> Bool {
  match self.routes.get(packet.dest) {
    Some(link) => {
      link.send(packet)
      true
    }
    None => false
  }
}

///|
/// 路由表条目数
pub fn Router::route_count(self : Router) -> Int {
  self.routes.length()
}

///|
/// 路由器名称
pub fn Router::name(self : Router) -> String {
  self.name
}

///|
/// 是否有到达指定目的的路由
pub fn Router::has_route(self : Router, dest : String) -> Bool {
  self.routes.contains(dest)
}
