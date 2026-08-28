///|
/// sim/environment.mbt — 环境与干扰仿真引擎
/// 12类进水负荷场景 + 26项故障场景 + 季节模式

///|
/// 12类典型进水负荷场景
pub fn load_scenarios() -> Array[LoadScenario] {
  [
    { id: 1, name: "典型日负荷", description: "居民生活污水典型日变化", category: "normal",
      flow_factor: 1.0, cod_factor: 1.0, nh4_factor: 1.0, tn_factor: 1.0, tp_factor: 1.0,
      temp_offset: 0.0, duration: 24.0 },
    { id: 2, name: "早高峰冲击", description: "7-9点水量水质双高峰", category: "shock",
      flow_factor: 1.5, cod_factor: 1.3, nh4_factor: 1.2, tn_factor: 1.2, tp_factor: 1.1,
      temp_offset: 0.0, duration: 2.0 },
    { id: 3, name: "晚高峰冲击", description: "18-21点水量水质双高峰", category: "shock",
      flow_factor: 1.4, cod_factor: 1.25, nh4_factor: 1.15, tn_factor: 1.15, tp_factor: 1.1,
      temp_offset: 0.0, duration: 3.0 },
    { id: 4, name: "雨季降雨冲击", description: "雨季水量大增, 浓度稀释, 可能溢流", category: "seasonal",
      flow_factor: 2.0, cod_factor: 0.5, nh4_factor: 0.6, tn_factor: 0.6, tp_factor: 0.5,
      temp_offset: -2.0, duration: 12.0 },
    { id: 5, name: "工业废水冲击", description: "工业废水COD/氨氮超标排入", category: "industrial",
      flow_factor: 1.1, cod_factor: 2.5, nh4_factor: 2.0, tn_factor: 2.0, tp_factor: 1.5,
      temp_offset: 0.0, duration: 4.0 },
    { id: 6, name: "冬季低水温", description: "水温10°C, 微生物活性降低", category: "seasonal",
      flow_factor: 0.85, cod_factor: 0.9, nh4_factor: 0.95, tn_factor: 0.9, tp_factor: 0.9,
      temp_offset: -10.0, duration: 24.0 },
    { id: 7, name: "夏季高水温", description: "水温28°C, 高负荷, 污泥膨胀风险", category: "seasonal",
      flow_factor: 1.15, cod_factor: 1.1, nh4_factor: 1.1, tn_factor: 1.1, tp_factor: 1.05,
      temp_offset: 8.0, duration: 24.0 },
    { id: 8, name: "管网漏损低水量", description: "管网破损, 进水量大幅减少", category: "normal",
      flow_factor: 0.6, cod_factor: 1.0, nh4_factor: 1.0, tn_factor: 1.0, tp_factor: 1.0,
      temp_offset: 0.0, duration: 8.0 },
    { id: 9, name: "节假日低负荷", description: "工厂放假, 仅生活污水", category: "normal",
      flow_factor: 0.7, cod_factor: 0.6, nh4_factor: 0.7, tn_factor: 0.65, tp_factor: 0.7,
      temp_offset: 0.0, duration: 24.0 },
    { id: 10, name: "管网冲刷冲击", description: "雨后管网沉积物冲刷, SS暴涨", category: "shock",
      flow_factor: 1.3, cod_factor: 1.8, nh4_factor: 1.1, tn_factor: 1.2, tp_factor: 1.3,
      temp_offset: 0.0, duration: 2.0 },
    { id: 11, name: "碳源不足", description: "BOD/TN比偏低, 反硝化受限", category: "normal",
      flow_factor: 1.0, cod_factor: 0.6, nh4_factor: 1.0, tn_factor: 1.1, tp_factor: 1.0,
      temp_offset: 0.0, duration: 12.0 },
    { id: 12, name: "pH异常冲击", description: "进水pH异常, 抑制微生物活性", category: "emergency",
      flow_factor: 1.0, cod_factor: 1.2, nh4_factor: 1.3, tn_factor: 1.2, tp_factor: 1.1,
      temp_offset: 0.0, duration: 4.0 },
  ]
}

///|
/// 26项典型生产故障场景
pub fn fault_scenarios() -> Array[FaultScenario] {
  [
    { id: 1, name: "污泥膨胀", category: "process", severity: "high", description: "SVI>150, 污泥沉降性能恶化",
      affected_unit: "二沉池", impact_cod: 15.0, impact_nh4: 0.0, impact_tp: 0.5 },
    { id: 2, name: "污泥老化", category: "process", severity: "medium", description: "SRT过长, 污泥活性下降",
      affected_unit: "AAO反应池", impact_cod: 5.0, impact_nh4: 2.0, impact_tp: 0.0 },
    { id: 3, name: "污泥中毒", category: "process", severity: "critical", description: "有毒物质抑制微生物活性",
      affected_unit: "AAO反应池", impact_cod: 30.0, impact_nh4: 15.0, impact_tp: 2.0 },
    { id: 4, name: "曝气不足", category: "process", severity: "high", description: "DO<1mg/L, 硝化受限",
      affected_unit: "好氧池", impact_cod: 8.0, impact_nh4: 10.0, impact_tp: 0.0 },
    { id: 5, name: "曝气过度", category: "process", severity: "medium", description: "DO>4mg/L, 能耗浪费, 污泥老化",
      affected_unit: "好氧池", impact_cod: -2.0, impact_nh4: -1.0, impact_tp: 0.0 },
    { id: 6, name: "碳源不足", category: "process", severity: "medium", description: "BOD/TN偏低, 反硝化受限",
      affected_unit: "缺氧池", impact_cod: 0.0, impact_nh4: 0.0, impact_tp: 0.0 },
    { id: 7, name: "二沉池跑泥", category: "process", severity: "high", description: "出水SS超标",
      affected_unit: "二沉池", impact_cod: 20.0, impact_nh4: 0.0, impact_tp: 1.0 },
    { id: 8, name: "滤池堵塞", category: "process", severity: "medium", description: "滤池水头损失增大",
      affected_unit: "深床滤池", impact_cod: 3.0, impact_nh4: 0.0, impact_tp: 0.0 },
    { id: 9, name: "提升泵故障", category: "equipment", severity: "high", description: "提升泵停运, 进水受限",
      affected_unit: "提升泵房", impact_cod: 0.0, impact_nh4: 0.0, impact_tp: 0.0 },
    { id: 10, name: "鼓风机故障", category: "equipment", severity: "critical", description: "鼓风机停运, 曝气中断",
      affected_unit: "鼓风机房", impact_cod: 20.0, impact_nh4: 25.0, impact_tp: 0.0 },
    { id: 11, name: "搅拌器故障", category: "equipment", severity: "medium", description: "搅拌器停运, 混合不均",
      affected_unit: "AAO反应池", impact_cod: 5.0, impact_nh4: 3.0, impact_tp: 1.0 },
    { id: 12, name: "脱水机故障", category: "equipment", severity: "low", description: "脱水机停运, 污泥积压",
      affected_unit: "脱水机房", impact_cod: 0.0, impact_nh4: 0.0, impact_tp: 0.0 },
    { id: 13, name: "阀门卡涩", category: "equipment", severity: "medium", description: "回流阀卡涩, 回流异常",
      affected_unit: "AAO反应池", impact_cod: 5.0, impact_nh4: 5.0, impact_tp: 1.0 },
    { id: 14, name: "仪表失灵", category: "equipment", severity: "medium", description: "DO仪/流量仪失灵",
      affected_unit: "全厂", impact_cod: 0.0, impact_nh4: 0.0, impact_tp: 0.0 },
    { id: 15, name: "进水超标", category: "quality", severity: "high", description: "进水COD/氨氮超过设计值",
      affected_unit: "进水", impact_cod: 10.0, impact_nh4: 5.0, impact_tp: 0.0 },
    { id: 16, name: "出水COD超标", category: "quality", severity: "high", description: "出水COD>50mg/L",
      affected_unit: "出水", impact_cod: 10.0, impact_nh4: 0.0, impact_tp: 0.0 },
    { id: 17, name: "出水氨氮超标", category: "quality", severity: "high", description: "出水NH4-N>5mg/L",
      affected_unit: "出水", impact_cod: 0.0, impact_nh4: 5.0, impact_tp: 0.0 },
    { id: 18, name: "出水总氮超标", category: "quality", severity: "high", description: "出水TN>15mg/L",
      affected_unit: "出水", impact_cod: 0.0, impact_nh4: 3.0, impact_tp: 0.0 },
    { id: 19, name: "出水总磷超标", category: "quality", severity: "high", description: "出水TP>0.5mg/L",
      affected_unit: "出水", impact_cod: 0.0, impact_nh4: 0.0, impact_tp: 0.3 },
    { id: 20, name: "硫化氢泄漏", category: "safety", severity: "critical", description: "污泥区H2S超标",
      affected_unit: "污泥处理区", impact_cod: 0.0, impact_nh4: 0.0, impact_tp: 0.0 },
    { id: 21, name: "有限空间缺氧", category: "safety", severity: "critical", description: "密闭空间O2不足",
      affected_unit: "污泥处理区", impact_cod: 0.0, impact_nh4: 0.0, impact_tp: 0.0 },
    { id: 22, name: "触电风险", category: "safety", severity: "high", description: "电气设备漏电",
      affected_unit: "全厂", impact_cod: 0.0, impact_nh4: 0.0, impact_tp: 0.0 },
    { id: 23, name: "消防隐患", category: "safety", severity: "medium", description: "消防设施异常",
      affected_unit: "全厂", impact_cod: 0.0, impact_nh4: 0.0, impact_tp: 0.0 },
    { id: 24, name: "全厂停电", category: "system", severity: "critical", description: "全厂供电中断",
      affected_unit: "全厂", impact_cod: 50.0, impact_nh4: 30.0, impact_tp: 5.0 },
    { id: 25, name: "自控系统故障", category: "system", severity: "high", description: "PLC/SCADA通信中断",
      affected_unit: "全厂", impact_cod: 10.0, impact_nh4: 5.0, impact_tp: 0.0 },
    { id: 26, name: "通信中断", category: "system", severity: "medium", description: "数据采集通信中断",
      affected_unit: "全厂", impact_cod: 0.0, impact_nh4: 0.0, impact_tp: 0.0 },
  ]
}

///|
/// 应用负荷场景到进水水质
pub fn apply_load_scenario(wq : WaterQuality, scenario : LoadScenario) -> WaterQuality {
  {
    ..wq,
    flow: wq.flow * scenario.flow_factor,
    cod: wq.cod * scenario.cod_factor,
    bod5: wq.bod5 * scenario.cod_factor,
    nh4_n: wq.nh4_n * scenario.nh4_factor,
    tn: wq.tn * scenario.tn_factor,
    tp: wq.tp * scenario.tp_factor,
    po4_p: wq.po4_p * scenario.tp_factor,
    temperature: wq.temperature + scenario.temp_offset,
  }
}

///|
/// 应用故障场景到出水水质
pub fn apply_fault_scenario(wq : WaterQuality, fault : FaultScenario) -> WaterQuality {
  {
    ..wq,
    cod: wq.cod + fault.impact_cod,
    nh4_n: wq.nh4_n + fault.impact_nh4,
    tp: wq.tp + fault.impact_tp,
  }
}

///|
/// 季节模式 — 根据季节调整参数
pub fn seasonal_params(season : String) -> (Double, Double, Double) {
  match season {
    "spring" => (5.0, 1.0, 1.0)
    "summer" => (8.0, 1.15, 1.1)
    "autumn" => (0.0, 1.0, 1.0)
    "winter" => (-10.0, 0.85, 0.9)
    "rainy" => (-2.0, 2.0, 0.5)
    _ => (0.0, 1.0, 1.0)
  }
}

///|
/// 生成日内负荷曲线 (24小时)
pub fn daily_load_curve(base_flow : Double) -> Array[Double] {
  let curve : Array[Double] = []
  for hour in 0..<24 {
    let base = 0.7
    let morning_peak = 0.3 * exp_d(-((hour.to_double() - 8.0) * (hour.to_double() - 8.0)) / 4.0)
    let evening_peak = 0.25 * exp_d(-((hour.to_double() - 19.0) * (hour.to_double() - 19.0)) / 6.0)
    let factor = base + morning_peak + evening_peak
    curve.push(base_flow * factor)
  }
  curve
}
