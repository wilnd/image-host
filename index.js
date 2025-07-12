const express = require('express');
const multer = require('multer');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// 启用 CORS
app.use(cors());

// 确保 uploads 目录存在
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

// 配置 multer 用于文件上传
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadsDir);
    },
    filename: function (req, file, cb) {
        // 生成唯一文件名：时间戳 + 随机数 + 原扩展名
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname);
        cb(null, uniqueSuffix + ext);
    }
});

// 文件过滤器 - 只允许图片文件
const fileFilter = (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp|bmp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
        return cb(null, true);
    } else {
        cb(new Error('只允许上传图片文件！'), false);
    }
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 10 * 1024 * 1024 // 限制文件大小为 10MB
    }
});

// 静态文件服务 - 提供图片访问
app.use('/uploads', express.static(uploadsDir));

// 静态文件服务 - 提供 HTML 测试页面
app.use(express.static(path.join(__dirname, 'public')));

// 上传单个图片
app.post('/upload', upload.single('image'), (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: '请选择要上传的图片文件'
            });
        }

        // 构建图片访问 URL
        const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
        
        res.json({
            success: true,
            message: '图片上传成功',
            data: {
                filename: req.file.filename,
                originalName: req.file.originalname,
                size: req.file.size,
                url: imageUrl
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: '上传失败',
            error: error.message
        });
    }
});

// 上传多个图片
app.post('/upload-multiple', upload.array('images', 10), (req, res) => {
    try {
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({
                success: false,
                message: '请选择要上传的图片文件'
            });
        }

        const uploadedFiles = req.files.map(file => ({
            filename: file.filename,
            originalName: file.originalname,
            size: file.size,
            url: `${req.protocol}://${req.get('host')}/uploads/${file.filename}`
        }));

        res.json({
            success: true,
            message: `成功上传 ${uploadedFiles.length} 张图片`,
            data: uploadedFiles
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: '上传失败',
            error: error.message
        });
    }
});

// 错误处理中间件
app.use((error, req, res, next) => {
    if (error instanceof multer.MulterError) {
        if (error.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({
                success: false,
                message: '文件大小超过限制（最大 10MB）'
            });
        }
    }
    
    res.status(500).json({
        success: false,
        message: error.message || '服务器内部错误'
    });
});

// 健康检查接口
app.get('/health', (req, res) => {
    res.json({
        success: true,
        message: '图床服务运行正常',
        timestamp: new Date().toISOString()
    });
});

// 获取已上传的图片列表
app.get('/images', (req, res) => {
    try {
        const files = fs.readdirSync(uploadsDir);
        const imageFiles = files.filter(file => {
            const ext = path.extname(file).toLowerCase();
            return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].includes(ext);
        });

        const images = imageFiles.map(filename => ({
            filename: filename,
            url: `${req.protocol}://${req.get('host')}/uploads/${filename}`,
            size: fs.statSync(path.join(uploadsDir, filename)).size
        }));

        res.json({
            success: true,
            data: images
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: '获取图片列表失败',
            error: error.message
        });
    }
});

// 删除图片
app.delete('/images/:filename', (req, res) => {
    try {
        const filename = req.params.filename;
        const filePath = path.join(uploadsDir, filename);
        
        if (!fs.existsSync(filePath)) {
            return res.status(404).json({
                success: false,
                message: '文件不存在'
            });
        }

        fs.unlinkSync(filePath);
        res.json({
            success: true,
            message: '文件删除成功'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: '删除文件失败',
            error: error.message
        });
    }
});

// 根路径
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: '图床服务 API',
        endpoints: {
            'POST /upload': '上传单个图片',
            'POST /upload-multiple': '上传多个图片（最多10张）',
            'GET /images': '获取所有图片列表',
            'DELETE /images/:filename': '删除指定图片',
            'GET /health': '健康检查'
        },
        baseUrl: `${req.protocol}://${req.get('host')}`
    });
});

app.listen(PORT, () => {
    console.log(`图床服务已启动，端口: ${PORT}`);
    console.log(`上传目录: ${uploadsDir}`);
    console.log(`服务地址: http://localhost:${PORT}`);
});
