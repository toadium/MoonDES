///|
/// sim/ai.mbt — AI智能分析层
/// 异常检测: 水质指标越限+突变检测
/// 预测性维护: 设备故障概率预测
/// 优化引擎: 多参数无梯度搜索
/// 趋势分析: 历史数据趋势识别

///|
/// AI分析结果
pub(all) struct AIAnalysis {
  anomalies : Array[Anomaly]
  maintenance_alerts : Array[MaintenanceAlert]
  optimization_params : Array[OptParam]
  risk_level : String       // "low" / "medium" / "high" / "critical"
  summary : String
} derive(Debug)

///|
/// 异常检测结果
pub(all) struct Anomaly {
  indicator : String        // 指标名
  value : Double            // 当前值
  threshold : Double        // 阈值
  severity : String         // "warning" / "critical"
  message : String          // 描述
} derive(Debug)

///|
/// 预测性维护告警
pub(all) struct MaintenanceAlert {
  equipment : String        // 设备名
  failure_prob : Double     // 故障概率 0-1
  remaining_hours : Double  // 预计剩余运行小时
  severity : String         // "info" / "warning" / "urgent"
  action : String           // 建议动作
} derive(Debug)

///|
/// 优化参数建议
pub(all) struct OptParam {
  name : String
  current : Double
  suggested : Double
  reason : String
} derive(Debug)

///|
/// 水质标准阈值 (一级A标准)
pub(all) struct QualityStandard {
  cod_max : Double
  nh4_max : Double
  tn_max : Double
  tp_max : Double
  ss_max : Double
  bod5_max : Double
} derive(Debug)

///|
/// 一级A排放标准
pub fn standard_1a() -> QualityStandard {
  { cod_max: 50.0, nh4_max: 5.0, tn_max: 15.0, tp_max: 0.5, ss_max: 10.0, bod5_max: 10.0 }
}

///|
/// 一级B排放标准
pub fn standard_1b() -> QualityStandard {
  { cod_max: 60.0, nh4_max: 8.0, tn_max: 20.0, tp_max: 1.0, ss_max: 20.0, bod5_max: 20.0 }
}

///|
/// 异常检测 — 检查出水水质是否超标
pub fn detect_anomalies(effluent : WaterQuality, standard : QualityStandard) -> Array[Anomaly] {
  let anomalies = []
  if effluent.cod > standard.cod_max {
    anomalies.push({ indicator: "COD", value: effluent.cod, threshold: standard.cod_max, severity: if effluent.cod > standard.cod_max * 1.2 { "critical" } else { "warning" }, message: "COD超标, 检查进水负荷和曝气系统" })
  }
  if effluent.nh4_n > standard.nh4_max {
    anomalies.push({ indicator: "氨氮", value: effluent.nh4_n, threshold: standard.nh4_max, severity: if effluent.nh4_n > standard.nh4_max * 1.5 { "critical" } else { "warning" }, message: "氨氮超标, 检查硝化效果和DO水平" })
  }
  if effluent.tn > standard.tn_max {
    anomalies.push({ indicator: "总氮", value: effluent.tn, threshold: standard.tn_max, severity: if effluent.tn > standard.tn_max * 1.3 { "critical" } else { "warning" }, message: "总氮超标, 检查内回流比和碳源" })
  }
  if effluent.tp > standard.tp_max {
    anomalies.push({ indicator: "总磷", value: effluent.tp, threshold: standard.tp_max, severity: if effluent.tp > standard.tp_max * 1.5 { "critical" } else { "warning" }, message: "总磷超标, 检查厌氧释磷和化学除磷" })
  }
  if effluent.ss > standard.ss_max {
    anomalies.push({ indicator: "SS", value: effluent.ss, threshold: standard.ss_max, severity: if effluent.ss > standard.ss_max * 2.0 { "critical" } else { "warning" }, message: "SS超标, 检查二沉池和污泥沉降性" })
  }
  if effluent.bod5 > standard.bod5_max {
    anomalies.push({ indicator: "BOD5", value: effluent.bod5, threshold: standard.bod5_max, severity: "warning", message: "BOD5超标, 检查有机物去除效率" })
  }
  anomalies
}

///|
/// 突变检测 — 检测水质指标相对历史的突变
pub fn detect_sudden_change(current : WaterQuality, history : Array[WaterQuality]) -> Array[Anomaly] {
  let anomalies = []
  if history.length() < 2 { return anomalies }
  let n = history.length()
  let recent = history[n - 1]
  let prev = history[n - 2]
  let cod_change = abs_d(current.cod - recent.cod) / max_d(recent.cod, 1.0)
  if cod_change > 0.2 {
    anomalies.push({ indicator: "COD突变", value: current.cod, threshold: recent.cod, severity: if cod_change > 0.5 { "critical" } else { "warning" }, message: "COD突变\{cod_change * 100.0}% (相对上一步)" })
  }
  let nh4_change = abs_d(current.nh4_n - recent.nh4_n) / max_d(recent.nh4_n, 1.0)
  if nh4_change > 0.3 {
    anomalies.push({ indicator: "氨氮突变", value: current.nh4_n, threshold: recent.nh4_n, severity: if nh4_change > 0.6 { "critical" } else { "warning" }, message: "氨氮突变\{nh4_change * 100.0}%" })
  }
  let _ = prev
  anomalies
}

///|
/// 预测性维护 — 基于设备运行状态预测故障
pub fn predict_maintenance(equipments : Array[EquipmentStatus]) -> Array[MaintenanceAlert] {
  let alerts = []
  for eq in equipments {
    let prob = 1.0 - eq.health / 100.0
    let remaining = eq.health / 100.0 * 8000.0
    if prob > 0.3 {
      let severity = if prob > 0.7 { "urgent" } else if prob > 0.5 { "warning" } else { "info" }
      let action = if prob > 0.7 { "立即停机检修" } else if prob > 0.5 { "安排计划检修" } else { "加强监测" }
      alerts.push({ equipment: eq.name, failure_prob: prob, remaining_hours: remaining, severity, action })
    }
  }
  alerts
}

///|
/// 优化引擎 — 无梯度坐标搜索
/// 尝试调整DO、内回流比、SRT、MLSS四个关键参数
/// 目标: 最小化出水COD+氨氮+总氮+总磷
pub fn optimize_parameters(wq : WaterQuality, cfg : PlantConfig) -> Array[OptParam] {
  let base_result = steady_state(wq, cfg)
  let base_cost = base_result.effluent.cod + base_result.effluent.nh4_n * 2.0 + base_result.effluent.tn + base_result.effluent.tp * 10.0
  let params = []
  // DO优化: 尝试0.5步长
  let do_options = [1.5, 2.0, 2.5, 3.0]
  let mut best_do = cfg.aao.do_setpoint
  let mut best_do_cost = base_cost
  for d in do_options {
    let test_cfg = { ..cfg, aao: { ..cfg.aao, do_setpoint: d } }
    let result = steady_state(wq, test_cfg)
    let cost = result.effluent.cod + result.effluent.nh4_n * 2.0 + result.effluent.tn + result.effluent.tp * 10.0
    if cost < best_do_cost {
      best_do_cost = cost
      best_do = d
    }
  }
  if abs_d(best_do - cfg.aao.do_setpoint) > 0.01 {
    let dir = if best_do > cfg.aao.do_setpoint { "提高" } else { "降低" }
    params.push({ name: "DO设定值", current: cfg.aao.do_setpoint, suggested: best_do, reason: "\{dir}DO可改善出水水质" })
  }
  // 内回流比优化
  let ir_options = [2.0, 3.0, 4.0, 5.0]
  let mut best_ir = cfg.aao.internal_recycle_ratio
  let mut best_ir_cost = base_cost
  for r in ir_options {
    let test_cfg = { ..cfg, aao: { ..cfg.aao, internal_recycle_ratio: r } }
    let result = steady_state(wq, test_cfg)
    let cost = result.effluent.cod + result.effluent.nh4_n * 2.0 + result.effluent.tn + result.effluent.tp * 10.0
    if cost < best_ir_cost {
      best_ir_cost = cost
      best_ir = r
    }
  }
  if abs_d(best_ir - cfg.aao.internal_recycle_ratio) > 0.01 {
    let dir = if best_ir > cfg.aao.internal_recycle_ratio { "提高" } else { "降低" }
    params.push({ name: "内回流比", current: cfg.aao.internal_recycle_ratio, suggested: best_ir, reason: "\{dir}内回流比可改善脱氮效果" })
  }
  // SRT优化
  let srt_options = [10.0, 12.0, 15.0, 18.0, 20.0]
  let mut best_srt = cfg.aao.srt
  let mut best_srt_cost = base_cost
  for s in srt_options {
    let test_cfg = { ..cfg, aao: { ..cfg.aao, srt: s } }
    let result = steady_state(wq, test_cfg)
    let cost = result.effluent.cod + result.effluent.nh4_n * 2.0 + result.effluent.tn + result.effluent.tp * 10.0
    if cost < best_srt_cost {
      best_srt_cost = cost
      best_srt = s
    }
  }
  if abs_d(best_srt - cfg.aao.srt) > 0.01 {
    let dir = if best_srt > cfg.aao.srt { "提高" } else { "降低" }
    params.push({ name: "SRT", current: cfg.aao.srt, suggested: best_srt, reason: "\{dir}SRT可改善污泥特性" })
  }
  // MLSS优化
  let mlss_options = [2500.0, 3000.0, 3500.0, 4000.0, 4500.0]
  let mut best_mlss = cfg.aao.mlss_target
  let mut best_mlss_cost = base_cost
  for m in mlss_options {
    let test_cfg = { ..cfg, aao: { ..cfg.aao, mlss_target: m } }
    let result = steady_state(wq, test_cfg)
    let cost = result.effluent.cod + result.effluent.nh4_n * 2.0 + result.effluent.tn + result.effluent.tp * 10.0
    if cost < best_mlss_cost {
      best_mlss_cost = cost
      best_mlss = m
    }
  }
  if abs_d(best_mlss - cfg.aao.mlss_target) > 0.01 {
    let dir = if best_mlss > cfg.aao.mlss_target { "提高" } else { "降低" }
    params.push({ name: "MLSS", current: cfg.aao.mlss_target, suggested: best_mlss, reason: "\{dir}MLSS可改善处理效率" })
  }
  params
}

///|
/// 趋势分析 — 分析时间序列趋势
pub(all) struct TrendAnalysis {
  indicator : String
  trend : String      // "rising" / "falling" / "stable"
  avg_value : Double
  change_rate : Double  // 变化率(%/step)
  forecast : Double   // 下一步预测值
} derive(Debug)

///|
/// 分析时间序列趋势
pub fn analyze_trend(values : Array[Double], indicator : String) -> TrendAnalysis {
  let n = values.length()
  if n < 2 {
    return { indicator, trend: "stable", avg_value: if n > 0 { values[0] } else { 0.0 }, change_rate: 0.0, forecast: if n > 0 { values[0] } else { 0.0 } }
  }
  let mut sum = 0.0
  for v in values { sum += v }
  let avg = sum / n.to_double()
  let recent = values[n - 1]
  let prev = values[n - 2]
  let change = if abs_d(prev) > 0.001 { (recent - prev) / abs_d(prev) * 100.0 } else { 0.0 }
  let trend = if change > 5.0 { "rising" } else if change < -5.0 { "falling" } else { "stable" }
  let forecast = recent + (recent - prev)
  { indicator, trend, avg_value: avg, change_rate: change, forecast }
}

///|
/// 综合AI分析
pub fn ai_analyze(result : SimResult, cfg : PlantConfig, equipments : Array[EquipmentStatus]) -> AIAnalysis {
  let anomalies = detect_anomalies(result.effluent, standard_1a())
  let maintenance = predict_maintenance(equipments)
  let optimization = optimize_parameters(result.influent, cfg)
  let mut risk = "low"
  let mut has_critical = false
  let mut has_warning = false
  for a in anomalies {
    if a.severity == "critical" { has_critical = true }
    if a.severity == "warning" { has_warning = true }
  }
  let mut has_urgent = false
  for m in maintenance {
    if m.severity == "urgent" { has_urgent = true }
  }
  if has_critical || has_urgent { risk = "critical" }
  else if has_warning { risk = "medium" }
  else if maintenance.length() > 0 { risk = "low" }
  let mut summary = "工艺运行"
  if risk == "critical" {
    summary = "存在严重异常, 需立即处理"
  } else if risk == "medium" {
    summary = "存在告警, 建议关注"
  } else if risk == "low" {
    summary = "运行正常, 有优化空间"
  } else {
    summary = "运行良好"
  }
  if optimization.length() > 0 {
    summary += ", AI建议调整\{optimization.length()}项参数"
  }
  { anomalies, maintenance_alerts: maintenance, optimization_params: optimization, risk_level: risk, summary }
}

///|
/// AI分析结果JSON导出
pub fn ai_analysis_json(analysis : AIAnalysis) -> String {
  let parts = []
  parts.push("\"risk_level\":\"\{analysis.risk_level}\"")
  parts.push("\"summary\":\"\{analysis.summary}\"")
  // anomalies
  parts.push("\"anomaly_count\":\{analysis.anomalies.length()}")
  let anomaly_arr = []
  for a in analysis.anomalies {
    anomaly_arr.push("{\"indicator\":\"\{a.indicator}\",\"value\":\{a.value},\"threshold\":\{a.threshold},\"severity\":\"\{a.severity}\",\"message\":\"\{a.message}\"}")
  }
  parts.push("\"anomalies\":[\{anomaly_arr.join(",")}]")
  // maintenance
  parts.push("\"maintenance_count\":\{analysis.maintenance_alerts.length()}")
  let maint_arr = []
  for m in analysis.maintenance_alerts {
    maint_arr.push("{\"equipment\":\"\{m.equipment}\",\"failure_prob\":\{m.failure_prob},\"remaining_hours\":\{m.remaining_hours},\"severity\":\"\{m.severity}\",\"action\":\"\{m.action}\"}")
  }
  parts.push("\"maintenance\":[\{maint_arr.join(",")}]")
  // optimization
  parts.push("\"optimization_count\":\{analysis.optimization_params.length()}")
  let opt_arr = []
  for o in analysis.optimization_params {
    opt_arr.push("{\"name\":\"\{o.name}\",\"current\":\{o.current},\"suggested\":\{o.suggested},\"reason\":\"\{o.reason}\"}")
  }
  parts.push("\"optimization\":[\{opt_arr.join(",")}]")
  "{\{parts.join(",")}}"
}
