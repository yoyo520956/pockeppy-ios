import Foundation

/// 内置代码模板（对标 Python IDE 的 snippet 面）
struct Snippet: Identifiable {
    let id: Int
    let name: String
    let desc: String
    let code: String
}

enum Snippets {
    static let all: [Snippet] = [
        Snippet(id: 0, name: "HTTP 请求", desc: "urllib 标准库 GET/POST", code: """
            # -*- coding: utf-8 -*-
            import json
            import urllib.request

            def get(url: str, headers: dict = None) -> dict:
                req = urllib.request.Request(url, headers=headers or {})
                with urllib.request.urlopen(req, timeout=15) as r:
                    return json.loads(r.read().decode("utf-8"))

            if __name__ == "__main__":
                data = get("https://api.github.com/repos/python/cpython")
                print(data["full_name"], data["stargazers_count"], "stars")
            """),
        Snippet(id: 1, name: "FastAPI 服务", desc: "需 v0.2 pip 通道安装 fastapi/uvicorn", code: """
            # -*- coding: utf-8 -*-
            # 依赖：fastapi + uvicorn（v0.2 的 pip 通道可装纯 Python 包）
            from fastapi import FastAPI

            app = FastAPI()
            cache: dict = {}

            @app.get("/ping")
            def ping() -> dict:
                return {"pong": True}

            @app.post("/memo")
            def add_memo(key: str, value: str) -> dict:
                cache[key] = value
                return {"saved": key, "total": len(cache)}

            @app.get("/memo/{key}")
            def get_memo(key: str) -> dict:
                return {"value": cache.get(key)}

            if __name__ == "__main__":
                import uvicorn
                uvicorn.run(app, host="0.0.0.0", port=8000)
            """),
        Snippet(id: 2, name: "数据分析", desc: "pandas 基础分析（v0.2 携带）", code: """
            # -*- coding: utf-8 -*-
            import io

            # pandas 版（v0.2 携带后启用）：
            # import pandas as pd
            # df = pd.read_csv(io.StringIO(raw))

            raw = '''name,age,city
            王小明,18,北京
            李小红,22,上海
            张小龙,25,深圳'''

            rows = raw.strip().splitlines()
            header = rows[0].split(",")
            data = [dict(zip(header, r.split(","))) for r in rows[1:]]
            ages = [int(d["age"]) for d in data]
            print(f"人数: {len(data)}, 平均年龄: {sum(ages)/len(ages):.1f}, 最大: {max(ages)}")
            """),
        Snippet(id: 3, name: "asyncio 并发", desc: "标准库 asyncio 实战", code: """
            # -*- coding: utf-8 -*-
            import asyncio
            import time

            async def worker(n: int, delay: float) -> str:
                await asyncio.sleep(delay)
                return f"任务{n} 完成 (用了 {delay}s)"

            async def main() -> None:
                t0 = time.time()
                results = await asyncio.gather(*(worker(i, 0.2 * i) for i in range(5)))
                for r in results:
                    print(r)
                print(f"总耗时 {time.time()-t0:.2f}s（串行需 2.0s）")

            asyncio.run(main())
            """),
        Snippet(id: 4, name: "SQLite 小数据库", desc: "标准库 sqlite3 增删改查", code: """
            # -*- coding: utf-8 -*-
            import sqlite3

            conn = sqlite3.connect(":memory:")
            cur = conn.cursor()
            cur.execute("CREATE TABLE todos (id INTEGER PRIMARY KEY, title TEXT, done INTEGER DEFAULT 0)")
            cur.executemany("INSERT INTO todos (title, done) VALUES (?, ?)",
                            [("买牛奶", 0), ("写周报", 1), ("约牙医", 0)])
            conn.commit()
            for row in cur.execute("SELECT id, title, done FROM todos"):
                mark = "✓" if row[2] else " "
                print(f"{row[0]}. [{mark}] {row[1]}")
            conn.close()
            """),
    ]
}
