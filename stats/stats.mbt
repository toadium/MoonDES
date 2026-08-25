///|
/// 统计摘要
///
/// 包含数据集的基本统计量。
pub(all) struct Summary {
  count : Int
  mean : Double
  stddev : Double
  min : Double
  max : Double
  sum : Double
} derive(Debug)

///|
/// 求和
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@stats.sum([1.0, 2.0, 3.0, 4.0, 5.0]), content="15")
/// }
/// ```
pub fn sum(data : Array[Double]) -> Double {
  let mut s = 0.0
  for x in data {
    s += x
  }
  s
}

///|
/// 均值
///
/// # Example
/// ```mbt check
/// test {
///   inspect(@stats.mean([1.0, 2.0, 3.0, 4.0, 5.0]), content="3")
/// }
/// ```
pub fn mean(data : Array[Double]) -> Double {
  if data.length() == 0 {
    return 0.0
  }
  sum(data) / data.length().to_double()
}

///|
/// 样本方差（除以 n-1）
pub fn variance(data : Array[Double]) -> Double {
  let n = data.length()
  if n <= 1 {
    return 0.0
  }
  let m = mean(data)
  let mut s = 0.0
  for x in data {
    let d = x - m
    s += d * d
  }
  s / (n - 1).to_double()
}

///|
/// 标准差
pub fn stddev(data : Array[Double]) -> Double {
  @math.pow(variance(data), 0.5)
}

///|
/// 最小值
pub fn min(data : Array[Double]) -> Double {
  if data.length() == 0 {
    return 0.0
  }
  let mut m = data[0]
  for x in data {
    if x < m {
      m = x
    }
  }
  m
}

///|
/// 最大值
pub fn max(data : Array[Double]) -> Double {
  if data.length() == 0 {
    return 0.0
  }
  let mut m = data[0]
  for x in data {
    if x > m {
      m = x
    }
  }
  m
}

///|
/// 直方图：将数据分到 bins 个等宽区间，返回每个区间的计数
///
/// # Example
/// ```mbt check
/// test {
///   let data = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
///   let hist = @stats.histogram(data, 5)
///   debug_inspect(hist, content="[2, 2, 2, 2, 2]")
/// }
/// ```
pub fn histogram(data : Array[Double], bins : Int) -> Array[Int] {
  if data.length() == 0 || bins <= 0 {
    return []
  }
  let lo = min(data)
  let hi = max(data)
  let width = (hi - lo) / bins.to_double()
  let counts : Array[Int] = []
  for _ in 0..<bins {
    counts.push(0)
  }
  if width == 0.0 {
    counts[0] = data.length()
    return counts
  }
  for x in data {
    let idx = ((x - lo) / width).to_int()
    let i = if idx >= bins { bins - 1 } else { idx }
    counts[i] = counts[i] + 1
  }
  counts
}

///|
/// 计算完整统计摘要
///
/// # Example
/// ```mbt check
/// test {
///   let s = @stats.summary([1.0, 2.0, 3.0, 4.0, 5.0])
///   inspect(s.count, content="5")
///   inspect(s.mean, content="3")
///   inspect(s.min, content="1")
///   inspect(s.max, content="5")
/// }
/// ```
pub fn summary(data : Array[Double]) -> Summary {
  {
    count: data.length(),
    mean: mean(data),
    stddev: stddev(data),
    min: min(data),
    max: max(data),
    sum: sum(data),
  }
}

///|
/// 协方差
pub fn covariance(x : Array[Double], y : Array[Double]) -> Double {
  let n = x.length()
  if n <= 1 || n != y.length() {
    return 0.0
  }
  let mx = mean(x)
  let my = mean(y)
  let mut s = 0.0
  for i in 0..<n {
    s += (x[i] - mx) * (y[i] - my)
  }
  s / (n - 1).to_double()
}

///|
/// 相关系数（Pearson）
pub fn correlation(x : Array[Double], y : Array[Double]) -> Double {
  let cov = covariance(x, y)
  let sx = stddev(x)
  let sy = stddev(y)
  if sx == 0.0 || sy == 0.0 {
    return 0.0
  }
  cov / (sx * sy)
}
