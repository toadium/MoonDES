# @stats — 统计聚合

提供数据集的统计量计算，包括均值、方差、标准差、直方图、协方差和相关系数。

## API

### 基本统计量

```mbt check
///|
test {
  let data = [1.0, 2.0, 3.0, 4.0, 5.0]
  inspect(@stats.sum(data), content="15")
  inspect(@stats.mean(data), content="3")
  inspect(@stats.min(data), content="1")
  inspect(@stats.max(data), content="5")
}
```

### 方差与标准差

```mbt check
///|
test {
  let data = [1.0, 2.0, 3.0, 4.0, 5.0]
  inspect(@stats.variance(data), content="2.5")
}
```

### 直方图

```mbt check
///|
test {
  let data = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
  let hist = @stats.histogram(data, 5)
  debug_inspect(hist, content="[2, 2, 2, 2, 2]")
}
```

### 统计摘要

```mbt check
///|
test {
  let s = @stats.summary([1.0, 2.0, 3.0, 4.0, 5.0])
  inspect(s.count, content="5")
  inspect(s.mean, content="3")
}
```

### 协方差与相关系数

```mbt check
///|
test {
  let x = [1.0, 2.0, 3.0, 4.0, 5.0]
  let y = [2.0, 4.0, 6.0, 8.0, 10.0]
  inspect(@stats.covariance(x, y), content="5")
}
```