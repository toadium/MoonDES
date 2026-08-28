///|
/// sim/biochemical.mbt — AAO生化模型 (简化ASM2d)
/// 厌氧区: 聚磷菌释磷 + 有机物发酵
/// 缺氧区: 反硝化脱氮 (NO3→N2)
/// 好氧区: 硝化(NH4→NO3) + 碳氧化 + 聚磷菌吸磷

///|
/// 厌氧区反应 — 聚磷菌释磷
pub fn anaerobic_zone(wq : WaterQuality, cfg : AAOConfig) -> WaterQuality {
  let hrt = calc_hrt(cfg.anaerobic_volume, wq.flow)
  let temp = wq.temperature
  let q_pp_t = temp_correction(cfg.q_pp, 1.07, temp)
  let available_cod = wq.cod * 0.15
  let p_release = q_pp_t * available_cod / 1000.0 * hrt
  let p_release_capped = min_d(p_release, wq.po4_p * 0.5 + 3.0)
  let organic_n = wq.tn - wq.nh4_n - wq.no3_n
  let ammonification = organic_n * 0.05 * hrt
  let mlss = cfg.mlss_target
  {
    ..wq,
    po4_p: wq.po4_p + p_release_capped,
    tp: wq.tp + p_release_capped * 0.8,
    nh4_n: wq.nh4_n + ammonification,
    cod: wq.cod * (1.0 - 0.05 * hrt),
    bod5: wq.bod5 * (1.0 - 0.03 * hrt),
    do_value: 0.0,
    mlss,
  }
}

///|
/// 缺氧区反应 — 反硝化脱氮
pub fn anoxic_zone(wq : WaterQuality, cfg : AAOConfig, internal_recycle : WaterQuality) -> WaterQuality {
  let mixed = mix_flows(wq, wq.flow, internal_recycle, wq.flow * cfg.internal_recycle_ratio)
  let hrt = calc_hrt(cfg.anoxic_volume, mixed.flow)
  let temp = mixed.temperature
  let mu_h_t = temp_correction(cfg.mu_h, cfg.theta_h, temp)
  let b_h_t = temp_correction(cfg.b_h, cfg.theta_h, temp)
  let cod_factor = mixed.cod / (cfg.k_s + mixed.cod)
  let no3_factor = mixed.no3_n / (cfg.k_no + mixed.no3_n)
  let do_inhibit = cfg.k_oh / (cfg.k_oh + mixed.do_value)
  let x_h = mixed.mlss * 0.75
  let denit_rate = mu_h_t * cfg.eta_g * cod_factor * no3_factor * do_inhibit * x_h / cfg.y_h
  let no3_removed = denit_rate * hrt * 0.001
  let no3_removed_capped = min_d(no3_removed, mixed.no3_n * 0.9)
  let cod_consumed = no3_removed_capped * 4.0
  let alkalinity_gain = no3_removed_capped * 3.57
  let _ = b_h_t // 保留用于衰减计算
  {
    ..mixed,
    no3_n: mixed.no3_n - no3_removed_capped,
    tn: mixed.tn - no3_removed_capped,
    cod: mixed.cod - cod_consumed,
    bod5: mixed.bod5 - cod_consumed * 0.6,
    do_value: 0.05,
    alkalinity: mixed.alkalinity + alkalinity_gain,
    mlss: cfg.mlss_target,
  }
}

///|
/// 好氧区反应 — 硝化 + 碳氧化 + 吸磷
pub fn oxic_zone(wq : WaterQuality, cfg : AAOConfig) -> WaterQuality {
  let hrt = calc_hrt(cfg.oxic_volume, wq.flow)
  let temp = wq.temperature
  let do_val = cfg.do_setpoint
  // 自养菌(硝化)
  let mu_a_t = temp_correction(cfg.mu_a, cfg.theta_a, temp)
  let b_a_t = temp_correction(cfg.b_a, cfg.theta_a, temp)
  let nh4_factor = wq.nh4_n / (cfg.k_nh + wq.nh4_n)
  let do_factor = do_val / (cfg.k_oa + do_val)
  let x_a = wq.mlss * 0.08
  let nitrif_rate = mu_a_t * nh4_factor * do_factor * x_a / cfg.y_a
  let nh4_removed = nitrif_rate * hrt * 0.001
  let nh4_removed_capped = min_d(nh4_removed, wq.nh4_n * 0.98)
  let no3_generated = nh4_removed_capped * 0.95
  let alkalinity_consumed_n = nh4_removed_capped * 7.14
  // 异养菌(碳氧化)
  let mu_h_t = temp_correction(cfg.mu_h, cfg.theta_h, temp)
  let cod_factor = wq.cod / (cfg.k_s + wq.cod)
  let do_factor_h = do_val / (cfg.k_oh + do_val)
  let x_h = wq.mlss * 0.75
  let carbon_rate = mu_h_t * cod_factor * do_factor_h * x_h / cfg.y_h
  let cod_removed = carbon_rate * hrt * 0.001
  let cod_removed_capped = min_d(cod_removed, wq.cod * 0.90)
  let bod_removed = cod_removed_capped * 0.6
  // 聚磷菌吸磷
  let p_uptake_rate = cfg.q_pp * cfg.y_po * do_factor * (wq.po4_p / (cfg.k_p + wq.po4_p))
  let p_uptake = p_uptake_rate * hrt * 0.001
  let p_uptake_capped = min_d(p_uptake, wq.po4_p * 0.95)
  // 衰减
  let _ = b_a_t
  let _ = b_h_t_unused(mu_h_t, x_h, hrt) // placeholder to avoid unused warnings
  {
    ..wq,
    nh4_n: wq.nh4_n - nh4_removed_capped,
    no3_n: wq.no3_n + no3_generated,
    tn: wq.tn - nh4_removed_capped * 0.9,
    cod: wq.cod - cod_removed_capped,
    bod5: wq.bod5 - bod_removed,
    po4_p: wq.po4_p - p_uptake_capped,
    tp: wq.tp - p_uptake_capped * 0.9,
    do_value: do_val,
    alkalinity: wq.alkalinity - alkalinity_consumed_n,
    mlss: cfg.mlss_target,
  }
}

///|
pub fn b_h_t_unused(_mu_h_t : Double, _x_h : Double, _hrt : Double) -> Double {
  0.0
}

///|
/// AAO三区串联仿真
pub fn aao_reactor(wq : WaterQuality, cfg : AAOConfig) -> (WaterQuality, WaterQuality, WaterQuality, WaterQuality) {
  // 外回流污泥混合
  let return_sludge : WaterQuality = {
    ..wq,
    cod: wq.cod * 0.3,
    nh4_n: wq.nh4_n * 0.5,
    no3_n: 0.0,
    po4_p: wq.po4_p * 2.0,
    ss: 0.0,
    mlss: cfg.mlss_target * 3.0,
    do_value: 0.0,
  }
  let q_in = wq.flow
  let q_r = q_in * cfg.external_recycle_ratio
  let influent_mixed = mix_flows(wq, q_in, return_sludge, q_r)
  // 厌氧区
  let after_anaerobic = anaerobic_zone(influent_mixed, cfg)
  // 缺氧区 (首次迭代)
  let initial_recycle : WaterQuality = {
    ..after_anaerobic,
    no3_n: 15.0,
    do_value: 1.5,
    nh4_n: 2.0,
  }
  let after_anoxic = anoxic_zone(after_anaerobic, cfg, initial_recycle)
  // 好氧区
  let after_oxic = oxic_zone(after_anoxic, cfg)
  // 修正迭代
  let after_anoxic_fixed = anoxic_zone(after_anaerobic, cfg, after_oxic)
  let after_oxic_fixed = oxic_zone(after_anoxic_fixed, cfg)
  (influent_mixed, after_anaerobic, after_anoxic_fixed, after_oxic_fixed)
}

///|
/// 计算SVI (污泥体积指数)
pub fn calc_svi(mlss : Double, fm_ratio : Double, temp : Double) -> Double {
  let base_svi = 100.0 + 50.0 * abs_d(fm_ratio - 0.15) * 10.0
  let temp_factor = 1.0 + (20.0 - temp) * 0.005
  let svi = base_svi * temp_factor
  clamp(svi, 50.0, 300.0)
}

///|
/// 计算SRT下的硝化效率
pub fn calc_nitrification_efficiency(srt : Double, temp : Double, do_val : Double) -> Double {
  let mu_a_t = temp_correction(1.0, 1.11, temp)
  let min_srt = 1.0 / (mu_a_t - temp_correction(0.15, 1.11, temp))
  let do_factor = do_val / (0.4 + do_val)
  if srt > min_srt {
    clamp((1.0 - min_srt / srt) * do_factor, 0.0, 0.99)
  } else {
    0.0
  }
}

///|
/// 计算脱氮效率
pub fn calc_denitrification_efficiency(internal_recycle : Double, cod_tn_ratio : Double, temp : Double) -> Double {
  let recycle_eff = internal_recycle / (1.0 + internal_recycle)
  let cn_factor = clamp((cod_tn_ratio - 2.0) / 6.0, 0.0, 1.0)
  let temp_factor = temp_correction(1.0, 1.06, temp) / temp_correction(1.0, 1.06, 20.0)
  clamp(recycle_eff * cn_factor * temp_factor, 0.0, 0.95)
}
