# 邮件润色工具使用说明

## 项目介绍

这是一个基于Vue.js开发的邮件润色工具，支持实时流式响应，能够与FastAPI后端无缝集成。用户可以输入原始邮件内容，系统会通过AI技术进行智能润色，提升邮件的专业度和表达效果。

## 主要特性

- ✨ **实时流式响应**：支持服务器端流式返回，实时显示润色进度
- 📝 **Markdown渲染**：支持Markdown格式的润色结果展示
- 🎨 **现代化UI**：简洁美观的用户界面，响应式设计
- 📱 **移动端适配**：完美适配移动设备
- 🔄 **一键复制**：快速复制润色后的内容
- 🧩 **组件化设计**：可轻松集成到其他页面

## 组件结构

### 1. EmailPolisherWidget.vue
主要的邮件润色组件，包含以下功能：

- 左侧输入区域：用户输入原始邮件
- 右侧输出区域：实时显示润色结果
- 流式响应处理
- Markdown渲染
- 复制功能

#### 使用方法：

```vue
<template>
  <EmailPolisherWidget 
    :height="'600px'"
    :api-endpoint="'/api/chat'"
  />
</template>

<script>
import EmailPolisherWidget from './components/EmailPolisherWidget.vue'

export default {
  components: {
    EmailPolisherWidget
  }
}
</script>
```

#### 组件属性：

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| height | String | '500px' | 组件高度 |
| apiEndpoint | String | '/api/chat' | API接口地址 |

### 2. EmailPolisher.vue
全屏版本的邮件润色组件，适用于独立页面使用。

### 3. EmailPolisherExample.vue
使用示例页面，展示如何集成和使用邮件润色组件。

## 后端集成

### FastAPI后端接口

后端需要提供以下API接口：

```python
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse

app = FastAPI()

@app.post("/api/chat")
async def handle_chat(request: Request):
    data = await request.json()
    prompt = data.get("prompt")
    
    return StreamingResponse(
        ask_ai(prompt, Config.system_contents["chat"]), 
        media_type="text/plain"
    )
```

### 请求格式

```json
{
  "prompt": "用户输入的原始邮件内容"
}
```

### 响应格式

服务器返回流式响应，内容类型为 `text/plain`，支持Markdown格式。

## 安装和运行

### 1. 安装依赖

```bash
npm install
```

### 2. 启动开发服务器

```bash
npm run dev
```

### 3. 构建生产版本

```bash
npm run build
```

## 技术栈

- **前端框架**：Vue.js 3
- **构建工具**：Vite
- **Markdown渲染**：marked
- **样式**：CSS3 with Scoped Styles
- **HTTP客户端**：Fetch API

## 文件结构

```
src/
├── components/
│   ├── EmailPolisher.vue          # 全屏版本组件
│   ├── EmailPolisherWidget.vue    # 小部件版本组件
│   └── EmailPolisherExample.vue   # 使用示例页面
├── App.vue                        # 主应用组件
├── main.js                        # 应用入口文件
└── style.css                      # 全局样式
```

## 自定义样式

组件使用Scoped CSS，支持通过CSS变量进行样式自定义：

```css
.email-polisher-widget {
  --primary-color: #667eea;
  --border-color: #e5e7eb;
  --text-color: #1f2937;
  --background-color: #f9fafb;
}
```

## 浏览器兼容性

- Chrome 60+
- Firefox 60+
- Safari 12+
- Edge 79+

## 故障排除

### 常见问题

1. **流式响应不工作**
   - 检查后端API是否正确返回流式响应
   - 确认Content-Type为text/plain

2. **Markdown渲染异常**
   - 检查marked库是否正确安装
   - 确认Markdown语法是否正确

3. **样式显示异常**
   - 检查CSS是否正确加载
   - 确认浏览器兼容性

### 调试技巧

1. 打开浏览器开发者工具查看网络请求
2. 查看控制台错误信息
3. 使用Vue DevTools调试组件状态

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 发送Pull Request

## 许可证

MIT License 