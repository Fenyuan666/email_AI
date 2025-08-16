<template>
  <div class="email-polisher-widget">
    <div class="widget-container">
      <!-- 左侧输入区域 -->
      <div class="input-section">
        <div class="section-header">
          <h4>原始邮件</h4>
          <span class="char-count">{{ originalEmail.length }} 字符</span>
        </div>
        <textarea
          v-model="originalEmail"
          placeholder="请输入您的邮件内容..."
          class="email-textarea"
          :disabled="isProcessing"
          rows="16"
        ></textarea>
        <button
          @click="processEmail"
          :disabled="isProcessing || !originalEmail.trim()"
          class="polish-button"
        >
          <span v-if="isProcessing" class="button-loading">
            <span class="spinner"></span>
            润色中...
          </span>
          <span v-else>✨ 润色邮件</span>
        </button>
      </div>

      <!-- 右侧输出区域 -->
      <div class="output-section">
        <div class="section-header">
          <h4>润色后的邮件</h4>
          <button
            v-if="renderedMarkdown && !isProcessing"
            @click="copyToClipboard"
            class="copy-button"
          >
            {{ copied ? '已复制' : '复制' }}
          </button>
        </div>
        <div class="output-container">
          <div
            v-if="renderedMarkdown"
            class="markdown-content"
            v-html="renderedMarkdown"
            ref="markdownContent"
          ></div>
          <div v-else class="placeholder">
            润色后的邮件将在这里显示
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { marked } from 'marked'

export default {
  name: 'EmailPolisherWidget',
  props: {
    height: {
      type: String,
      default: '80vh'
    },
    // apiEndpoint: {
    //   type: String,
    //   default: '/api/chat'
    // }
  },
  data() {
    return {
      originalEmail: '',
      polishedEmail: '',
      renderedMarkdown: '',
      isProcessing: false,
      copied: false
    }
  },
  methods: {
    async processEmail() {
      if (!this.originalEmail.trim()) return
      
      this.isProcessing = true
      this.polishedEmail = ''
      this.renderedMarkdown = ''
      
      const url = '/api/mail'

      try {
        const response = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            prompt: this.originalEmail
          })
        })
        
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        
        const reader = response.body.getReader()
        const decoder = new TextDecoder()
        
        while (true) {
          const { done, value } = await reader.read()
          
          if (done) break
          
          const chunk = decoder.decode(value, { stream: true })
          this.polishedEmail += chunk
          
          // 实时渲染markdown
          this.renderedMarkdown = marked(this.polishedEmail)
        }
        
      } catch (error) {
        console.error('处理邮件时发生错误:', error)
        this.renderedMarkdown = `<div class="error-message">处理邮件时发生错误: ${error.message}</div>`
      } finally {
        this.isProcessing = false
      }
    },
    
    async copyToClipboard() {
      try {
        // 复制带格式的HTML内容
        const htmlContent = this.renderedMarkdown;
        const textContent = this.polishedEmail;
        
        // 创建一个临时的div元素来获取纯文本
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = htmlContent;
        const plainText = tempDiv.textContent || tempDiv.innerText || '';
        
        // 使用现代的clipboard API写入HTML和文本
        await navigator.clipboard.write([
          new ClipboardItem({
            'text/html': new Blob([htmlContent], { type: 'text/html' }),
            'text/plain': new Blob([plainText], { type: 'text/plain' })
          })
        ]);
        
        this.copied = true
        setTimeout(() => {
          this.copied = false
        }, 2000)
      } catch (error) {
        console.error('复制失败:', error)
        // 降级方案：复制纯文本
        try {
          await navigator.clipboard.writeText(this.polishedEmail)
          this.copied = true
          setTimeout(() => {
            this.copied = false
          }, 2000)
        } catch (fallbackError) {
          console.error('降级复制也失败:', fallbackError)
        }
      }
    }
  },
  mounted() {
    // 配置marked选项
    marked.setOptions({
      breaks: true,
      gfm: true,
      sanitize: false
    })
  }
}
</script>

<style scoped>
.email-polisher-widget {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  padding: 20px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  backdrop-filter: blur(10px);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.widget-container {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  flex: 1;
  min-height: 0;
}

.input-section,
.output-section {
  display: flex;
  flex-direction: column;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.3);
  backdrop-filter: blur(5px);
  min-height: 0;
  overflow: hidden;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-header h4 {
  margin: 0;
  color: #1f2937;
  font-size: 16px;
  font-weight: 600;
}

.char-count {
  color: #6b7280;
  font-size: 12px;
}

.email-textarea {
  flex: 1;
  resize: none;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  padding: 16px;
  font-size: 14px;
  font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', monospace;
  line-height: 1.5;
  background-color: #f9fafb;
  transition: border-color 0.2s;
}

.email-textarea:focus {
  outline: none;
  border-color: #3b82f6;
  background-color: white;
}

.email-textarea:disabled {
  background-color: #f3f4f6;
  color: #6b7280;
  cursor: not-allowed;
}

.polish-button {
  margin-top: 16px;
  padding: 12px 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.polish-button:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.polish-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.button-loading {
  display: flex;
  align-items: center;
  gap: 8px;
}

.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid transparent;
  border-top: 2px solid white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.output-container {
  flex: 1;
  position: relative;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  background-color: #f9fafb;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.markdown-content {
  padding-left: 16px;
  padding-right: 16px;
  padding-top: 2px;
  padding-bottom: 2px;
  flex: 1;
  overflow-y: auto;
  font-size: 14px;
  line-height: 1.4;
  color: #1f2937;
  word-wrap: break-word;
  white-space: normal;
}

.placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #9ca3af;
  font-style: italic;
}

.copy-button {
  padding: 6px 12px;
  background: #f3f4f6;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 12px;
  color: #374151;
  cursor: pointer;
  transition: all 0.2s;
}

.copy-button:hover {
  background: #e5e7eb;
}



.error-message {
  color: #ef4444;
  background: #fef2f2;
  padding: 12px;
  border-radius: 6px;
  border: 1px solid #fecaca;
  margin: 16px;
}

/* Markdown 样式 */
.markdown-content :deep(*) {
  margin: 0;
  padding: 0;
}

.markdown-content :deep(h1),
.markdown-content :deep(h2),
.markdown-content :deep(h3),
.markdown-content :deep(h4),
.markdown-content :deep(h5),
.markdown-content :deep(h6) {
  margin: 8px 0 4px 0;
  color: #1f2937;
  font-weight: 600;
  line-height: 1.2;
}

.markdown-content :deep(p) {
  margin: 0 0 6px 0;
  color: #374151;
  line-height: 1.4;
}

.markdown-content :deep(ul),
.markdown-content :deep(ol) {
  margin: 0 0 6px 0;
  padding-left: 20px;
  line-height: 1.4;
}

.markdown-content :deep(li) {
  margin: 0 0 2px 0;
  line-height: 1.4;
}

.markdown-content :deep(code) {
  background: #f3f4f6;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: 'SF Mono', Monaco, 'Cascadia Code', monospace;
  font-size: 13px;
  color: #e11d48;
  line-height: 1.2;
}

.markdown-content :deep(pre) {
  background: #f3f4f6;
  padding: 8px;
  border-radius: 6px;
  overflow-x: auto;
  margin: 2px 0;
  font-family: 'SF Mono', Monaco, 'Cascadia Code', monospace;
  font-size: 13px;
  line-height: 1.3;
}

.markdown-content :deep(blockquote) {
  border-left: 4px solid #e5e7eb;
  padding-left: 16px;
  margin: 2px 0;
  color: #6b7280;
  font-style: italic;
  line-height: 1.3;
}

.markdown-content :deep(strong) {
  font-weight: 600;
  color: #1f2937;
}

.markdown-content :deep(em) {
  font-style: italic;
}

.markdown-content :deep(br) {
  line-height: 0;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .widget-container {
    grid-template-columns: 1fr;
    gap: 16px;
    height: auto;
  }
  
  .input-section,
  .output-section {
    min-height: 300px;
  }
  
  .email-textarea {
    min-height: 200px;
  }
}
</style> 