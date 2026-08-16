# Java toolchain: dual OpenJDK

[简体中文](../zh-CN/jdk.md)

The workstation keeps two OpenJDK releases side by side: one to try the
newest features, one as a stable baseline.

## Why both versions are installed

| Package | Version | Role |
|---|---|---|
| `jdk-openjdk` | 26 (rolling with the repo) | System default, newest features |
| `jdk21-openjdk` | 21 LTS | Stable baseline, existing ecosystem |

**`jdk-openjdk`: newest features**

- The system default `java` / `javac` point at it, so the command line uses the
  latest JDK out of the box.
- New language and runtime capabilities (virtual threads, pattern matching,
  sealed classes and their evolution) only land in new releases; projects
  depending on them need this one.
- It rolls with the CachyOS repository and stays at the newest major release.

**`jdk21-openjdk`: stable LTS**

- 21 is a long-term support release with ongoing security updates and the
  mainstream target runtime of the current enterprise ecosystem (Spring Boot
  and other frameworks, legacy projects, CI images).
- Projects that must build or run on 21 select it via `JAVA_HOME` or their
  build tool without touching the system default.
- It is the fallback: if a new release introduces a compatibility problem,
  switching the whole environment back takes one command.

The two coexist without interfering: OpenJDK releases live side by side under
`/usr/lib/jvm/`, and `archlinux-java` manages which one is the default.

## Usage

```bash
archlinux-java status                    # list installed environments and the default
sudo archlinux-java set java-21-openjdk  # switch to LTS temporarily
sudo archlinux-java set java-26-openjdk  # switch back to the newest
```

Set `JAVA_HOME` to `/usr/lib/jvm/java-26-openjdk` or
`/usr/lib/jvm/java-21-openjdk` as needed.

## Restore behavior

`packages/pacman-explicit.txt` lists both `jdk-openjdk` and `jdk21-openjdk`;
`./scripts/install-packages.sh` installs both and then points the default Java
environment at the current major version of `jdk-openjdk` (read dynamically
from the installed package, so it follows the rolling repository without
script changes).
