# cpu-temp-filter：状态栏 CPU 温度去抖

本机（工程样片 `Genuine Intel(R) 0000`，`coretemp` 暴露 14 个核心传感器）的
DTS 读数**双稳态**：单个核心与 `Package id 0` 会在真实的 45–60 °C 与 Tjmax 哨兵值
`100.0 °C` 之间反复翻转，而同一时刻其他核心仍是 45–77 °C、整机 CPU 利用率只有
个位数。Noctalia 的状态栏温度默认就取 `Package id 0`（`src/system/cpu_temp_sensor.cpp`
里 `coretemp` 的 `Package id` 优先级为 0），于是读数在 `54` 与 `100` 之间乱跳。

内核侧无法修正这个读数，所以本模块在用户态起一个常驻过滤器：扫全部核心、判掉哨兵、
平滑后把结果发布成一个**伪 hwmon 输入文件**，让 Noctalia 读它。

## 安装

```bash
./scripts/module.sh install cpu-temp-filter
```

安装会：投放 `~/.local/bin/cpu-temp-filter`（0755）与
`~/.config/systemd/user/cpu-temp-filter.service`，覆盖前备份到
`~/.local/state/cachyos-config/module-backups/<文件名>`（同名只保留一份），
然后 `daemon-reload` + `enable --now`。

## Noctalia 侧配置

`configs/apps/noctalia/.config/noctalia/config.toml` 已包含：

```toml
[system.monitor]
cpu_temp_sensor_path = "/run/user/1000/cpu-temp/temp1_input"
cpu_poll_seconds = 2.0
cpu_temp_activity_threshold = 75.0
cpu_temp_critical_threshold = 95.0
```

约束（写在 `cpu_temp_sensor.cpp` 里，写错直接不可用）：

- 文件名**必须**匹配 `temp*_input`，否则报
  `configured CPU temperature sensor is not a temp*_input file`。
- 内容 `>= 1000` 时按毫度除以 1000，`< 0` 视为解析失败。
- 配置了 `cpu_temp_sensor_path` 就**没有**自动探测兜底：路径不存在时该统计显示为不可用。
  所以模块必须先装，或把该键删掉退回自动探测。
- 路径里的 `/run/user/1000` 是按 uid 写死的；uid 不是 1000 的机器需要把这一行改成
  `$(XDG_RUNTIME_DIR)/cpu-temp/temp1_input`，再 `noctalia msg config-reload`。
- 阈值只影响配色（75 起染色、95 报红），不触发任何降频。

## 过滤器行为

| 参数 | 值 | 含义 |
|---|---|---|
| `TICK` / `WRITE_EVERY` | 0.25 s / 1 s | 扫描频率 / 发布频率 |
| `WINDOW` | 12 | 3 s 中值窗 |
| `ALPHA` | 0.08 | EMA 系数，时间常数约 3 s |
| `HOT` / `SUSPECT_OK` / `DIE_WIDE` | 90 °C / 88 °C / 0.8 | 「整个 die 一起热」的判定 |
| `SPREAD` | 15 °C | 最高核心最多比 die 共识高多少 |

判据只有一条物理不变量：**真热会让大多数核心一起动，坏读数只动一两个核心**。
`Package id` 项直接排除；未通过 die 共识时剔掉 `>= 95 °C` 的读数；最后取「共识中位数
+15 °C」以内的最大核心值，再走中值窗与 EMA。

已知取舍：单核满载而其余核心仍凉时（如单线程编译）会按 die 共识显示，偏低约 20 °C；
若 12/14 个核心同时报 Tjmax 会被当作真过热（与真实过热不可区分，本机未出现）。

## 验证

```bash
systemctl --user is-active cpu-temp-filter.service
cat "$XDG_RUNTIME_DIR/cpu-temp/temp1_input"     # 例如 52809（微度）
noctalia msg config-get system.monitor.cpu_temp_sensor_path
```

`raw core max` 报 `100000` 时，过滤值应稳定在 45–58 °C（空闲），1 s 步长小于 4.5 °C；
全核满载时应平滑爬到 90 °C 左右，同时 `scaling_cur_freq` 保持在全核睿频、不随温度下降。

## 卸载

```bash
./scripts/module.sh uninstall cpu-temp-filter
```

卸载不会改 Noctalia 配置，记得自行删掉 `[system.monitor].cpu_temp_sensor_path`
（或改回自动探测）后 `noctalia msg config-reload`。

## 范围

只影响 Noctalia 状态栏与控制中心的 sysmon 数据。`sensors`、btop 等直读 hwmon 的工具
仍会看到 100 °C 哨兵值，属另一条链路，本模块不处理，也**不**引入任何按温度降频的逻辑。
