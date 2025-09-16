# 【前戏】Rust Web 服务器从零开始开发学习文档

## 📚 项目概述

这是一个用 Rust 从零开始实现的简单 HTTP 服务器项目，用于学习 Rust Web 开发的基础知识。
## 项目来源
该项目是学习B站视频[Rust Web 全栈开发教程【完结】](https://www.bilibili.com/video/BV1RP4y1G7KF?spm_id_from=333.788.videopod.episodes&vd_source=d56107846eb42ec63f2c0661c9818246&p=6)中【前戏】部分的代码实现。
大家可以多多关注B站上的作者[软件工艺师](https://space.bilibili.com/361469957/?spm_id_from=333.788.upinfo.detail.click)

## 🏗️ 项目结构

```
httpserver/
├── Cargo.toml          # 项目配置和依赖
├── data/
│   └── orders.json     # JSON 数据文件
├── public/             # 静态文件目录
│   ├── index.html      # 首页
│   ├── health.html     # 健康检查页
│   ├── 404.html        # 404错误页
│   └── styles.css      # CSS样式文件
└── src/
    ├── main.rs         # 程序入口
    ├── server.rs       # 服务器实现
    ├── router.rs       # 路由处理
    └── handler.rs      # 请求处理器
```

## 🔧 第一步：项目初始化

### 1.1 创建项目
```bash
cargo new httpserver
cd httpserver
```

### 1.2 配置 Cargo.toml
```toml
[package]
name = "httpserver"
version = "0.1.0"
edition = "2024"

[dependencies]
http = { path = "../http" }        # 本地HTTP库
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
```

## 🌐 第二步：理解HTTP基础

### 2.1 HTTP请求结构
在<mcfolder name="http" path="e:\\i-hdu\\项目\\Orginone_C#2Rust\\runoob-greeting\\s1\\http"></mcfolder>中定义了：
- <mcfile name="httprequest.rs" path="e:\\i-hdu\\项目\\Orginone_C#2Rust\\runoob-greeting\\s1\\http\\src\\httprequest.rs"></mcfile> - HTTP请求解析
- <mcfile name="httpresponse.rs" path="e:\\i-hdu\\项目\\Orginone_C#2Rust\\runoob-greeting\\s1\\http\\src\\httpresponse.rs"></mcfile> - HTTP响应构建

## 🖥️ 第三步：服务器核心实现

### 3.1 主程序入口 - main.rs
```rust
use crate::server::Server;

mod server;
mod router;
mod handler;

fn main() {
    let server = Server::new("localhost:3000");
    server.run();
}
```

**学习要点：**
- `mod` 关键字用于声明模块
- `Server::new()` 创建服务器实例
- `server.run()` 启动服务器

### 3.2 服务器实现 - server.rs

```rust
use super::router::Router;
use http::httprequest::HttpRequest;
use std::io::prelude::*;
use std::net::TcpListener;
use std::str;

pub struct Server<'a>{
    socket_addr: &'a str,
}

impl<'a> Server<'a>{
    pub fn new(socket_addr: &'a str) -> Self {
        Server { socket_addr }    
    }

    pub fn run(&self) {
        let connection_listener = TcpListener::bind(self.socket_addr).unwrap();
        println!("Running on {}", self.socket_addr);

        for stream in connection_listener.incoming() {
            let mut stream = stream.unwrap();
            println!("Connection established");

            let mut read_buffer = [0; 200];
            stream.read(&mut read_buffer).unwrap();
            let req: HttpRequest = String::from_utf8(read_buffer.to_vec()).unwrap().into();
            Router::route(req, &mut stream);
        }
    }
}
```

**学习要点：**
- `TcpListener::bind()` - 绑定端口监听连接
- 生命周期注解 `'a` - 确保字符串引用有效
- `unwrap()` - 简化错误处理（生产环境应使用更健壮的错误处理）
- 缓冲区读取和UTF-8转换

## 🛣️ 第四步：路由处理

### 4.1 路由实现 - router.rs

```rust
use super::handler::{Handler, PageNotFoundHandler, StaticPageHandler, WebServiceHandler};
use http::{httprequest, httprequest::HttpRequest, httpresponse::HttpResponse};
use std::io::prelude::*;

pub struct Router;

impl Router {
    pub fn route(req: HttpRequest, stream: &mut impl Write) -> () {
        match req.method {
            httprequest::Method::Get => match &req.resource {
                httprequest::Resource::Path(s) => {
                    let route: Vec<&str> = s.split("/").collect();
                    match route[1] {
                        "api" => {
                            let resp: HttpResponse = WebServiceHandler::handle(&req);
                            let _ = resp.send_response(stream);
                        }
                        _ => {
                            let resp: HttpResponse = StaticPageHandler::handle(&req);
                            let _ = resp.send_response(stream);
                        }
                    }
                }
            },
            _ => {
                let resp: HttpResponse = PageNotFoundHandler::handle(&req);
                let _ = resp.send_response(stream);
            }
        }
    }
}
```

**学习要点：**
- 模式匹配 (`match`) - Rust的核心特性
- 路径分割和路由逻辑
-  trait 对象的使用

## 🎯 第五步：请求处理器

### 5.1 Handler Trait 定义

```rust
pub trait Handler {
    fn handle(req: &HttpRequest) -> HttpResponse<'_>;
    
    fn load_file(file_name: &str) -> Option<String> {
        let default_path = format!("{}/public", env!("CARGO_MANIFEST_DIR"));
        let public_path = env::var("PUBLIC_PATH").unwrap_or(default_path);
        let full_path = format!("{}/{}", public_path, file_name);

        let contents = fs::read_to_string(full_path);
        contents.ok()
    }
}
```

**学习要点：**
- Trait 定义和方法默认实现
- 环境变量和宏的使用 (`env!`, `env::var`)
- 文件读取和错误处理

### 5.2 静态页面处理器

```rust
impl Handler for StaticPageHandler {
    fn handle(req: &HttpRequest) -> HttpResponse<'_> {
        let http::httprequest::Resource::Path(s) = &req.resource;
        let route: Vec<&str> = s.split("/").collect();
        
        match route[1] {
            "" => HttpResponse::new("200", None, Self::load_file("index.html")),
            "health" => HttpResponse::new("200", None, Self::load_file("health.html")),
            path => match Self::load_file(path) {
                Some(contents) => {
                    let mut map: HashMap<&str, &str> = HashMap::new();
                    if path.ends_with(".css") {
                        map.insert("Content-Type", "text/css");
                    } else if path.ends_with(".js") {
                        map.insert("Content-Type", "text/javascript");
                    } else {
                        map.insert("Content-Type", "text/html");
                    }
                    HttpResponse::new("200", Some(map), Some(contents))
                },
                None => HttpResponse::new("404", Some(HashMap::new()), Self::load_file("404.html")),
            }
        }
    }
}
```

### 5.3 Web服务处理器

```rust
impl WebServiceHandler {
    fn load_json() -> Vec<OrderStatus> {
        let default_path = format!("{}/data", env!("CARGO_MANIFEST_DIR"));
        let data_path = env::var("DATA_PATH").unwrap_or(default_path);
        let full_path = format!("{}/{}", data_path, "orders.json");
        
        let json_contents = fs::read_to_string(full_path);
        let orders: Vec<OrderStatus> = serde_json::from_str(json_contents.unwrap().as_str()).unwrap();
        orders
    }
}
```

## 📁 第六步：静态文件组织

### 6.1 HTML文件结构

**index.html:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <link rel="stylesheet" href="styles.css">
    <title>Index!</title>
</head>
<body>
    <h1>Hello, welcome to home page</h1>
    <p>This is the index page for the web site</p>
</body>
</html>
```

**styles.css:**
```css
h1{
    color: red;
    margin-left: 25px;
}
```

## 🚀 第七步：运行和测试

### 7.1 启动服务器
```bash
cargo run -p httpserver
```

### 7.2 测试端点
- 首页: `http://localhost:3000`
- 健康检查: `http://localhost:3000/health`
- API端点: `http://localhost:3000/api/shipping/orders`
- 静态文件: `http://localhost:3000/styles.css`

## 💡 第八步：学习总结和进阶

### 8.1 学到的Rust概念
1. **模块系统** - mod, use, pub
2. **生命周期** - `'a` 注解
3. **Trait** - 定义和实现
4. **模式匹配** - match 表达式
5. **错误处理** - Option, Result, unwrap
6. **文件IO** - 读写操作
7. **字符串处理** - 分割和转换
8. **网络编程** - TcpListener, 流处理

### 8.2 可以改进的地方
1. **错误处理** - 使用 `?` 操作符和自定义错误类型
2. **并发处理** - 使用 async/await 或多线程
3. **配置管理** - 使用配置文件
4. **中间件** - 添加日志、认证等中间件
5. **测试** - 添加单元测试和集成测试

### 8.3 下一步学习建议
1. 学习 `actix-web` 或 `warp` 等成熟的Web框架
2. 探索数据库集成 (SQLx, Diesel)
3. 学习异步编程
4. 了解Rust的测试框架
5. 学习部署和Docker化

这个项目是一个很好的起点，帮助你理解Rust Web开发的基本概念和模式！
        