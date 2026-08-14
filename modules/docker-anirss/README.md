# docker-anirss：ANI-RSS + qBittorrent 容器栈管理助手

管理 `~/Projects/ASS/docker-compose.yml` 定义的 ANI-RSS 与 qBittorrent 容器栈：
启动后打印两个服务地址并自动打开 ANI-RSS 页面。容器未运行时通过
`sg docker` 进入 docker 组执行，避免重复输 sudo 密码。

这是个人用途脚本（需要自备 compose 文件），不属于通用快照恢复内容，单独安装。

## 安装

```bash
./scripts/install-docker-anirss.sh
```

安装后：

```bash
docker-ass          # 启动并打开 ANI-RSS
docker-ass qbit     # 启动并打开 qBittorrent
docker-ass status   # 查看容器状态
```

compose 文件默认 `$HOME/Projects/ASS/docker-compose.yml`，可用环境变量
`ANI_RSS_COMPOSE_FILE` 覆盖。

## 卸载

```bash
modules/docker-anirss/uninstall.sh
```
