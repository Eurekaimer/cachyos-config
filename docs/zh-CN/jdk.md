# Java 工具链：双版本 OpenJDK 与 Maven

[English](../en/jdk.md)

工作站保留两个 OpenJDK 发行版，分别承担「尝鲜」与「稳定」两种角色。

## 为什么同时安装两个版本

| 软件包 | 版本 | 角色 |
|---|---|---|
| `jdk-openjdk` | 26（跟随仓库滚动） | 系统默认环境，使用最新特性 |
| `jdk21-openjdk` | 21 LTS | 稳定基线，兼容既有生态 |

**`jdk-openjdk`：最新特性**

- 系统默认的 `java` / `javac` 指向它，命令行直接使用最新 JDK。
- 语言与运行时的新能力（虚拟线程、模式匹配、密封类等后续演进）只在新版本中提供；依赖新特性的项目需要它。
- 随 CachyOS 仓库滚动更新，始终是仓库中的最新主版本。

**`jdk21-openjdk`：稳定 LTS**

- 21 是长期支持版本，获得持续的安全更新，且是当前企业生态（Spring Boot 等框架、老项目、CI 镜像）的主流目标运行时。
- 需要以 21 构建或运行的项目，通过 `JAVA_HOME` 或构建工具指定即可，无需改动系统默认。
- 作为兜底：新版本若出现兼容性问题，一条命令即可整体切回 LTS。

两者并行安装互不干扰：OpenJDK 各版本共存于 `/usr/lib/jvm/`，由 `archlinux-java` 管理默认环境。

## 使用

```bash
archlinux-java status                    # 列出已安装环境及默认项
sudo archlinux-java set java-21-openjdk  # 临时切到 LTS
sudo archlinux-java set java-26-openjdk  # 切回最新
```

`JAVA_HOME` 按需指向 `/usr/lib/jvm/java-26-openjdk` 或 `/usr/lib/jvm/java-21-openjdk`。

## Maven

Maven 直接以仓库软件包 `maven` 安装——不用 SDKMAN、不手工解包，`mvn` 随仓库滚动，`pacman -Syu` 即可升级。

它与其他 Java 构建工具一样选择 JVM：设置了 `JAVA_HOME` 用 `JAVA_HOME`，否则用系统默认的 `java`。

- 未设置 `JAVA_HOME` 时，`mvn` 运行在最新环境（`jdk-openjdk`）上。
- 需要以 LTS 构建时，把 `JAVA_HOME` 指向 21 环境：

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
mvn -v           # 确认实际使用的 JDK
```

## 恢复行为

`packages/pacman-explicit.txt` 同时收录 `jdk-openjdk`、`jdk21-openjdk` 与 `maven`，`./scripts/install-packages.sh` 会安装三者，并自动把默认 Java 环境设为 `jdk-openjdk` 的当前主版本（版本号从已安装包动态读取，仓库滚动到新主版本后自动跟随，无需修改脚本）。
