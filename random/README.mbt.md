# @random — 随机数与分布采样

基于 MoonBit 标准库 `@random.Rand`（ChaCha8 算法）的分布采样扩展。

## API

### 创建 RNG

```mbt check
test {
  let rng = @random.new_rng()
  let x = @random.uniform(rng, min=0.0, max=1.0)
  assert_true(x >= 0.0 && x < 1.0)
}
```

### 分布采样

| 函数 | 分布 | 参数 |
|------|------|------|
| `uniform(rng, min=, max=)` | 均匀分布 [min, max) | min, max |
| `exponential(rng, lambda=)` | 指数分布（均值 1/lambda） | lambda > 0 |
| `normal(rng, mean=, std=)` | 正态分布（Box-Muller） | mean, std |
| `poisson(rng, lambda=)` | 泊松分布（Knuth 算法） | lambda > 0 |
| `bernoulli(rng, p=)` | 伯努利分布 | 0 <= p <= 1 |
| `randint(rng, min=, max=)` | 离散均匀 [min, max] | min, max |