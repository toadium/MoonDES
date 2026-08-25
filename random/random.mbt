///|
/// 创建随机数生成器（使用 ChaCha8 算法）
///
/// # Example
/// ```mbt check
/// test {
///   let rng = @random.new_rng()
///   let x = @random.uniform(rng, min=0.0, max=1.0)
///   assert_true(x >= 0.0 && x < 1.0)
/// }
/// ```
pub fn new_rng() -> @rand.Rand {
  @rand.Rand::chacha8()
}

///|
/// 均匀分布采样 [min, max)
///
/// # Example
/// ```mb?check
/// test {
///   let rng = @random.new_rng()
///   let x = @random.uniform(rng, min=10.0, max=20.0)
///   assert_true(x >= 10.0 && x < 20.0)
/// }
/// ```
pub fn uniform(rng : @rand.Rand, min~ : Double, max~ : Double) -> Double {
  min + (max - min) * rng.double()
}

///|
/// 指数分布采样（参数 lambda > 0，均值为 1/lambda）
///
/// 使用逆变换法：X = -ln(U) / lambda
pub fn exponential(rng : @rand.Rand, lambda~ : Double) -> Double {
  let u = rng.double()
  let u_safe = if u > 0.0 { u } else { 0.0000000001 }
  -@math.ln(u_safe) / lambda
}

///|
/// 正态分布采样（均值 mean，标准差 std）
///
/// 使用 Box-Muller 变换
pub fn normal(rng : @rand.Rand, mean~ : Double, std~ : Double) -> Double {
  let u1 = rng.double()
  let u2 = rng.double()
  let u1_safe = if u1 > 0.0 { u1 } else { 0.0000000001 }
  let r = @math.pow(-2.0 * @math.ln(u1_safe), 0.5)
  let theta = 2.0 * @math.PI * u2
  mean + std * r * @math.cos(theta)
}

///|
/// 泊松分布采样（参数 lambda > 0，均值为 lambda）
///
/// 使用 Knuth 算法
pub fn poisson(rng : @rand.Rand, lambda~ : Double) -> Int {
  let l = @math.exp(-lambda)
  let mut k = 0
  let mut p = 1.0
  for ;; {
    k = k + 1
    p = p * rng.double()
    if p <= l {
      break
    }
  }
  k - 1
}

///|
/// 伯努利分布采样（成功概率 p，返回 true 表示成功）
pub fn bernoulli(rng : @rand.Rand, p~ : Double) -> Bool {
  rng.double() < p
}

///|
/// 离散均匀分布采样 [min, max]
pub fn randint(rng : @rand.Rand, min~ : Int, max~ : Int) -> Int {
  min + rng.int(limit=max - min + 1)
}
