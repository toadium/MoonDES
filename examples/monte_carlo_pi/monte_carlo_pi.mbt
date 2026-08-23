///|
/// 示例：Monte Carlo 估算 PI
///
/// 在 [0,1)×[0,1) 单位正方形内随机撒点，
/// 落入四分之一圆（x²+y² < 1）内的比例 ≈ π/4。
/// 估算 PI = 4 * inside / total。
///
/// 运行：moon run ./examples/monte_carlo_pi --target wasm
fn main {
  let rng = @random.new_rng()
  let n = 100000
  let mut inside = 0
  let ratios : Array[Double] = []

  // 采样 10 批，每批 10000 点，观察收敛
  for batch in 0..<10 {
    let batch_n = 10000
    for _ in 0..<batch_n {
      let x = @random.uniform(rng, min=0.0, max=1.0)
      let y = @random.uniform(rng, min=0.0, max=1.0)
      if x * x + y * y < 1.0 {
        inside = inside + 1
      }
    }
    let total = (batch + 1) * batch_n
    let pi_est = 4.0 * inside.to_double() / total.to_double()
    ratios.push(pi_est)
  }

  let pi_estimate = 4.0 * inside.to_double() / n.to_double()
  let error = pi_estimate - 3.141592653589793
  let abs_error = if error < 0.0 { -error } else { error }

  println("Monte Carlo PI Estimation")
  println("=========================")
  println("Total samples: \{n}")
  println("Inside circle: \{inside}")
  println("")
  println("PI estimate:   \{pi_estimate}")
  println("PI actual:     3.141592653589793")
  println("Absolute error: \{abs_error}")
  println("")
  println("Batch convergence:")
  for i in 0..<ratios.length() {
    let n_i = (i + 1) * 10000
    println("  N=\{n_i}  PI≈\{ratios[i]}")
  }
  println("")
  let s = @stats.summary(ratios)
  println("Statistics over batches:")
  println("  Mean:   \{s.mean}")
  println("  StdDev: \{s.stddev}")
  println("  Min:    \{s.min}")
  println("  Max:    \{s.max}")
}
