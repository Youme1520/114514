#!/usr/bin/env python3
"""向 Flutter Android 工程注入阿里云 Maven 镜像，规避 Maven 中央仓库 429 限流。

只注入「依赖仓库」（allprojects.repositories 或
dependencyResolutionManagement.repositories），绝不改动 pluginManagement 块——
因为 pluginManagement 里的 flutter-plugin-loader 由 includeBuild 提供，
往里加自定义 maven 仓库会触发 Gradle 校验错误导致插件解析失败。
"""
import re
import sys
from pathlib import Path

GROOVY_MIRRORS = "\n".join([
    "        maven { url 'https://maven.aliyun.com/repository/google' }",
    "        maven { url 'https://maven.aliyun.com/repository/public' }",
    "        maven { url 'https://maven.aliyun.com/repository/central' }",
    "        maven { url 'https://maven.aliyun.com/repository/gradle-plugin' }",
])

KTS_MIRRORS = "\n".join([
    '        maven("https://maven.aliyun.com/repository/google")',
    '        maven("https://maven.aliyun.com/repository/public")',
    '        maven("https://maven.aliyun.com/repository/central")',
    '        maven("https://maven.aliyun.com/repository/gradle-plugin")',
])


def inject(path: Path) -> bool:
    s = path.read_text(encoding="utf-8")
    is_kts = path.suffix == ".kts"
    mirrors = KTS_MIRRORS if is_kts else GROOVY_MIRRORS

    # 目标 1：allprojects { repositories { ... } }
    pat = re.compile(r"(allprojects\s*\{[^}]*?repositories\s*\{)", re.S)
    new, cnt = pat.subn(lambda m: m.group(1) + "\n" + mirrors, s)

    if not cnt:
        # 目标 2（新版 Flutter）：dependencyResolutionManagement { repositories { ... } }
        pat2 = re.compile(
            r"(dependencyResolutionManagement\s*\{[^}]*?repositories\s*\{)", re.S
        )
        new, cnt = pat2.subn(lambda m: m.group(1) + "\n" + mirrors, s)

    if cnt:
        path.write_text(new, encoding="utf-8")
        print(f"[OK] {path} injected mirrors")
        return True
    print(f"[SKIP] {path} no allprojects/dependencyResolutionManagement block")
    return False


def main() -> int:
    candidates = [
        Path("android/build.gradle"),
        Path("android/build.gradle.kts"),
    ]
    found_any = False
    for p in candidates:
        if p.exists():
            found_any = True
            inject(p)
    if not found_any:
        print("[WARN] no android/build.gradle(.kts) found")
    return 0


if __name__ == "__main__":
    sys.exit(main())
