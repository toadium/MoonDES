#!/usr/bin/env python3
"""根据设计规格书精确布置构筑物位置"""
import sys

LAYOUT = {
    0:  (0, 0, 0),        # 进水检查井 80x60 场地地面
    1:  (0, 0, -27),      # 粗格栅间 70x5 进水渠道 北边缘
    2:  (-37, 0, 0),      # 细格栅间 5x50 配水渠道 西边缘
    3:  (-30, 0, 0),      # 提升泵房 3x3
    4:  (-24, 0, 0),      # 曝气沉砂池 3.5x3
    5:  (-18, 0, 0),      # 初沉池 3.5x3
    6:  (-10, 0, -6),     # 缺氧池 5x5 AAO北半幅
    7:  (-2, 0, -6),      # 厌氧池 8x6
    8:  (7, 0, -6),       # 好氧池 10x2
    12: (-8, 0, 6),       # 搅拌机 6x12 AAO南半幅
    11: (6, 0, 6),        # 曝气器 20x12
    9:  (20, 0, -7),      # 接触区 10x12 北侧
    10: (20, 0, 8),       # 二沉池 9x12 南侧
    13: (30, 0, -7),      # 深床滤池 11x2
    14: (30, 0, 5),       # 紫外消毒渠 11x2
    15: (36, 0, -7),      # 清水池 5x5
    16: (36, 0, 5),       # 出水计量槽 5x5
    17: (24, 0, -20),     # 污泥浓缩池 6x4 东北
    18: (32, 0, -20),     # 污泥储池 8x8
    19: (24, 0, -26),     # 脱水机房 8x2
    20: (32, 0, -26),     # 污泥干化间 8x2
    25: (-28, 0, -25),    # 办公楼 4x5 西北
    24: (-20, 0, -25),    # 实验室 4x5
    23: (-20, 0, -18),    # 配电间 5x5
    22: (-28, 0, -18),    # 加药间 6x5
    27: (-12, 0, 22),     # 仓库 8x6 南侧
    26: (-2, 0, 22),      # 维修车间 6x6
    21: (8, 0, 22),       # 鼓风机房 8x6
    28: (0, 0, -28),       # 场地地基 6x7 北边缘
    29: (0, 0, 15),       # 主干道 5x6
    30: (15, 0, -15),     # 次干道
    31: (-12, 0, 0),      # 管道节点A
    32: (8, 0, -3),       # 管道节点B
    33: (27, 0, 0),       # 管道节点C
    34: (37, 0, 0),       # 出水渠道
    35: (-35, 0, 0),      # 闸门
    36: (0, 0, 28),       # 厂区围墙 南边缘
    37: (-28, 0, 12),     # 绿化带
    38: (-20, 0, 18),     # 停车场
    39: (-35, 0, 10),     # 门卫室
}

LABELS = [
    '进水检查井','粗格栅间','细格栅间','提升泵房','曝气沉砂池','初沉池',
    '缺氧池','厌氧池','好氧池','接触区','二沉池','曝气器','搅拌机',
    '深床滤池','紫外消毒渠','清水池','出水计量槽',
    '污泥浓缩池','污泥储池','脱水机房','污泥干化间',
    '鼓风机房','加药间','配电间','实验室','办公楼',
    '维修车间','仓库','场地地基','主干道','次干道',
    '管道节点A','管道节点B','管道节点C',
    '出水渠道','闸门','厂区围墙','绿化带','停车场','门卫室'
]

def fix_obj(inp, outp):
    with open(inp) as f:
        lines = f.readlines()
    output = []
    idx = -1
    count = 0
    for line in lines:
        if line.startswith('o '):
            idx = count
            count += 1
            output.append(line)
        elif line.startswith('v '):
            p = line.strip().split()
            x, y, z = float(p[1]), float(p[2]), float(p[3])
            if idx in LAYOUT:
                x += LAYOUT[idx][0]; y += LAYOUT[idx][1]; z += LAYOUT[idx][2]
            output.append('v %.8f %.8f %.8f\n' % (x, y, z))
        else:
            output.append(line)
    with open(outp, 'w') as f:
        f.writelines(output)

    # 验证
    with open(outp) as f:
        lines = f.readlines()
    cur = None; idx = -1; verts = []; all_info = []
    for line in lines:
        if line.startswith('o '):
            if cur and verts:
                xs=[v[0] for v in verts]; ys=[v[1] for v in verts]; zs=[v[2] for v in verts]
                all_info.append((idx, LABELS[idx] if idx < len(LABELS) else cur,
                    (min(xs)+max(xs))/2, (min(ys)+max(ys))/2, (min(zs)+max(zs))/2,
                    max(xs)-min(xs), max(ys)-min(ys), max(zs)-min(zs)))
            cur = line.strip().split()[1]; idx += 1; verts = []
        elif line.startswith('v '):
            p = line.strip().split()
            verts.append((float(p[1]), float(p[2]), float(p[3])))
    if cur and verts:
        xs=[v[0] for v in verts]; ys=[v[1] for v in verts]; zs=[v[2] for v in verts]
        all_info.append((idx, LABELS[idx] if idx < len(LABELS) else cur,
            (min(xs)+max(xs))/2, (min(ys)+max(ys))/2, (min(zs)+max(zs))/2,
            max(xs)-min(xs), max(ys)-min(ys), max(zs)-min(zs)))

    print('=' * 100)
    print('  厂区构筑物布置表 (依据设计规格书 3.1 厂区总平面布置)')
    print('=' * 100)
    print('  序  名称          中心(X,Y,Z)          尺寸(W×H×D)      区域')
    print('  ' + '-' * 94)
    for i, name, cx, cy, cz, sx, sy, sz in all_info:
        pos = '(%6.1f,%4.1f,%6.1f)' % (cx, cy, cz)
        dim = '%4.1f×%4.1f×%4.1f' % (sx, sy, sz)
        if cx < -15 and cz < -15: zone = '西北-办公'
        elif cx > 20 and cz < -15: zone = '东北-污泥'
        elif cz > 15: zone = '南侧-辅助'
        elif cx < -10: zone = '西侧-一级'
        elif cx > 25: zone = '东侧-三级'
        else: zone = '中央-AAO'
        print('  %2d  %-12s  %s  %s  %s' % (i, name, pos, dim, zone))

    # 重叠检查
    print('\n  ' + '-' * 94)
    aao_names = {'缺氧池','厌氧池','好氧池','接触区','二沉池','曝气器','搅拌机'}
    overlaps_aao = []; overlaps_other = []
    for i in range(len(all_info)):
        for j in range(i+1, len(all_info)):
            a, b = all_info[i], all_info[j]
            ox = min(a[2]+a[5]/2, b[2]+b[5]/2) - max(a[2]-a[5]/2, b[2]-b[5]/2)
            oz = min(a[4]+a[7]/2, b[4]+b[7]/2) - max(a[4]-a[7]/2, b[4]-b[7]/2)
            oy = min(a[3]+a[6]/2, b[3]+b[6]/2) - max(a[3]-a[6]/2, b[3]-b[6]/2)
            if ox > 0.3 and oz > 0.3 and oy > 0.3:
                if a[1] in aao_names and b[1] in aao_names:
                    overlaps_aao.append((a[1], b[1], ox, oz))
                else:
                    overlaps_other.append((a[1], b[1], ox, oz))

    print('  AAO内部重叠(同池设备,可接受): %d 对' % len(overlaps_aao))
    for o in overlaps_aao:
        print('    %s <-> %s (dx=%.1f, dz=%.1f)' % (o[0], o[1], o[2], o[3]))
    print('  跨区域重叠(需检查): %d 对' % len(overlaps_other))
    for o in overlaps_other:
        print('    ! %s <-> %s (dx=%.1f, dz=%.1f)' % (o[0], o[1], o[2], o[3]))

    oob = [info for info in all_info if abs(info[2]) > 40 or abs(info[4]) > 30]
    print('  超出厂区范围: %d 个' % len(oob))
    for o in oob:
        print('    ! %s at (%.1f, %.1f)' % (o[1], o[2], o[4]))

    # 工艺流向
    prim = [a for a in all_info if a[1] in ['提升泵房','曝气沉砂池','初沉池']]
    sec = [a for a in all_info if a[1] in ['缺氧池','厌氧池','好氧池']]
    tert = [a for a in all_info if a[1] in ['深床滤池','紫外消毒渠','清水池']]
    pX = sum(a[2] for a in prim)/len(prim)
    sX = sum(a[2] for a in sec)/len(sec)
    tX = sum(a[2] for a in tert)/len(tert)
    print('\n  工艺流向: 一级(X=%.1f) -> 二级(X=%.1f) -> 三级(X=%.1f) %s' % (
        pX, sX, tX, 'OK' if pX < sX < tX else 'CHECK'))

    intake = [a for a in all_info if '进水' in a[1]]
    outlet = [a for a in all_info if '出水' in a[1]]
    if intake and outlet:
        dist = ((outlet[0][2]-intake[0][2])**2 + (outlet[0][4]-intake[0][4])**2)**0.5
        print('  进出水距离: %.1fm (进水X=%.1f -> 出水X=%.1f)' % (dist, intake[0][2], outlet[0][2]))

    print('\n  生成: %s (%d 对象)' % (outp, count))

if __name__ == '__main__':
    inp = sys.argv[1] if len(sys.argv) > 1 else 'dsh-test/wastewater-plant-100score.obj.bak'
    outp = sys.argv[2] if len(sys.argv) > 2 else 'dsh-test/wastewater-plant-100score.obj'
    fix_obj(inp, outp)
