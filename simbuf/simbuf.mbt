///|
/// 仿真输出缓冲区
///
/// 全局可变缓冲区，用于捕获仿真输出代替 println。
/// 每个 run() 调用前 clear()，结束后 to_string() 获取全部输出。
///
/// # Example
/// ```mbt check
/// test {
///   @simbuf.clear()
///   @simbuf.println("hello")
///   @simbuf.println("world")
///   assert_eq(@simbuf.to_string(), "hello\nworld")
/// }
/// ```
let buffer : Array[String] = []

///|
/// 清空缓冲区
pub fn clear() -> Unit {
  while buffer.length() > 0 {
    ignore(buffer.pop())
  }
}

///|
/// 追加一行（带换行）
pub fn println(s : String) -> Unit {
  buffer.push(s)
}

///|
/// 追加不带换行
pub fn print(s : String) -> Unit {
  // 合并到最后一行或新建
  if buffer.length() > 0 {
    let last = buffer[buffer.length() - 1]
    buffer[buffer.length() - 1] = last + s
  } else {
    buffer.push(s)
  }
}

///|
/// 获取全部输出（换行连接）
pub fn to_string() -> String {
  let mut result = ""
  for i in 0..<buffer.length() {
    if i > 0 {
      result += "\n"
    }
    result += buffer[i]
  }
  result
}

///|
/// 当前行数
pub fn line_count() -> Int {
  buffer.length()
}
