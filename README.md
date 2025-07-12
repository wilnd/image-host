# 图床系统

一个基于 Node.js + Express + Multer 的简单图床系统，支持图片上传、管理和访问。

## 功能特性

- ✅ 支持单个图片上传
- ✅ 支持多个图片批量上传（最多10张）
- ✅ 自动生成唯一文件名
- ✅ 支持多种图片格式（JPG、PNG、GIF、WebP、BMP）
- ✅ 文件大小限制（最大10MB）
- ✅ 跨域支持（CORS）
- ✅ 图片列表管理
- ✅ 图片删除功能
- ✅ 健康检查接口
- ✅ 美观的 Web 测试界面

## 安装和运行

### 开发环境（macOS/Linux/Windows）

#### 1. 安装依赖

```bash
npm install
```

#### 2. 启动服务

```bash
# 生产环境
npm start

# 开发环境（需要安装 nodemon）
npm run dev
```

服务将在 `http://localhost:3000` 启动。

### Ubuntu Linux 生产环境部署

#### 1. 自动部署（推荐）

```bash
# 给部署脚本执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

#### 2. 手动部署

```bash
# 更新系统
sudo apt update

# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 安装项目依赖
npm install

# 创建 systemd 服务
sudo cp deploy.sh /etc/systemd/system/image-host.service
sudo systemctl daemon-reload
sudo systemctl enable image-host
sudo systemctl start image-host
```

#### 3. 配置 Nginx 反向代理

```bash
# 安装 Nginx
sudo apt install -y nginx

# 复制配置文件
sudo cp nginx.conf /etc/nginx/sites-available/image-host

# 创建软链接
sudo ln -s /etc/nginx/sites-available/image-host /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

#### 4. 配置防火墙

```bash
# 给防火墙脚本执行权限
chmod +x setup-firewall.sh

# 运行防火墙配置
./setup-firewall.sh
```

#### 5. 服务管理

```bash
# 启动服务
sudo systemctl start image-host

# 停止服务
sudo systemctl stop image-host

# 重启服务
sudo systemctl restart image-host

# 查看状态
sudo systemctl status image-host

# 查看日志
sudo journalctl -u image-host -f
```

#### 6. 监控服务

```bash
# 给监控脚本执行权限
chmod +x monitor.sh

# 运行监控检查
./monitor.sh

# 设置定时监控（每小时检查一次）
echo "0 * * * * /path/to/monitor.sh" | sudo crontab -
```

## API 接口

### 基础信息

- **服务地址**: `http://localhost:3000`
- **图片存储目录**: `./uploads/`

### 接口列表

#### 1. 上传单个图片
- **URL**: `POST /upload`
- **参数**: `image` (文件)
- **响应示例**:
```json
{
  "success": true,
  "message": "图片上传成功",
  "data": {
    "filename": "1703123456789-123456789.jpg",
    "originalName": "example.jpg",
    "size": 1024000,
    "url": "http://localhost:3000/uploads/1703123456789-123456789.jpg"
  }
}
```

#### 2. 上传多个图片
- **URL**: `POST /upload-multiple`
- **参数**: `images` (文件数组，最多10个)
- **响应示例**:
```json
{
  "success": true,
  "message": "成功上传 3 张图片",
  "data": [
    {
      "filename": "1703123456789-123456789.jpg",
      "originalName": "image1.jpg",
      "size": 1024000,
      "url": "http://localhost:3000/uploads/1703123456789-123456789.jpg"
    }
  ]
}
```

#### 3. 获取图片列表
- **URL**: `GET /images`
- **响应示例**:
```json
{
  "success": true,
  "data": [
    {
      "filename": "1703123456789-123456789.jpg",
      "url": "http://localhost:3000/uploads/1703123456789-123456789.jpg",
      "size": 1024000
    }
  ]
}
```

#### 4. 删除图片
- **URL**: `DELETE /images/:filename`
- **响应示例**:
```json
{
  "success": true,
  "message": "文件删除成功"
}
```

#### 5. 健康检查
- **URL**: `GET /health`
- **响应示例**:
```json
{
  "success": true,
  "message": "图床服务运行正常",
  "timestamp": "2023-12-21T10:30:00.000Z"
}
```

## 使用示例

### 使用 curl 上传图片

```bash
# 上传单个图片
curl -X POST -F "image=@/path/to/your/image.jpg" http://localhost:3000/upload

# 上传多个图片
curl -X POST -F "images=@/path/to/image1.jpg" -F "images=@/path/to/image2.jpg" http://localhost:3000/upload-multiple
```

### 使用 JavaScript 上传图片

```javascript
// 上传单个图片
async function uploadImage(file) {
    const formData = new FormData();
    formData.append('image', file);
    
    const response = await fetch('http://localhost:3000/upload', {
        method: 'POST',
        body: formData
    });
    
    return await response.json();
}

// 使用示例
const fileInput = document.getElementById('fileInput');
fileInput.addEventListener('change', async (e) => {
    const file = e.target.files[0];
    const result = await uploadImage(file);
    console.log(result);
});
```

## Web 测试界面

访问 `http://localhost:3000` 可以使用内置的 Web 测试界面：

- 单个图片上传测试
- 多个图片批量上传测试
- 图片列表查看
- 图片删除功能
- 实时预览上传的图片

## 配置说明

### 文件大小限制
默认限制为 10MB，可以在 `index.js` 中修改：

```javascript
limits: {
    fileSize: 10 * 1024 * 1024 // 修改这里的数值
}
```

### 支持的文件格式
默认支持：JPG、JPEG、PNG、GIF、WebP、BMP

可以在 `index.js` 中的 `fileFilter` 函数中修改：

```javascript
const allowedTypes = /jpeg|jpg|png|gif|webp|bmp/;
```

### 端口配置
默认端口为 3000，可以通过环境变量 `PORT` 修改：

```bash
PORT=8080 npm start
```

## 目录结构

```
image-host/
├── index.js          # 主服务文件
├── package.json      # 项目配置
├── README.md         # 说明文档
├── uploads/          # 图片存储目录（自动创建）
└── public/           # 静态文件目录
    └── index.html    # Web 测试页面
```

## 注意事项

1. 确保 `uploads` 目录有写入权限
2. 生产环境建议配置反向代理（如 Nginx）
3. 可以根据需要添加用户认证和权限控制
4. 建议定期清理未使用的图片文件
5. 生产环境建议使用云存储服务替代本地存储

## 许可证

ISC License 