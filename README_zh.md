[English](./README.md)

# Claudable

<img src="./assets/Claudable.png" alt="CLovable" style="border-radius: 12px; width: 100%;" />
<div align="center">
<h3>連接 Claude Code。建構您想要的。即時部署。</h3>

<p>由 <a href="https://opactor.ai">OPACTOR</a> 驅動</p>
</div>
<p align="center">
<a href="https://discord.gg/NJNbafHNQC">
<img src="https://img.shields.io/badge/Discord-加入社群-7289da?style=flat&logo=discord&logoColor=white" alt="加入 Discord 社群">
</a>
<a href="https://opactor.ai">
<img src="https://img.shields.io/badge/OPACTOR-網站-000000?style=flat&logo=web&logoColor=white" alt="OPACTOR 網站">
</a>
<a href="https://twitter.com/aaron_xong">
<img src="https://img.shields.io/badge/追蹤-@aaron__xong-000000?style=flat&logo=x&logoColor=white" alt="追蹤 Aaron">
</a>
</p>

## Claudable 是什麼？

Claudable 是一個強大的基於 Next.js 的網頁應用程式建構器，它結合了 **C**laude Code（也支援 Cursor CLI！）的先進 AI 代理功能與 **Lovable** 簡單直觀的應用程式建構體驗。只需描述您的應用程式想法——「我想要一個帶有深色模式的任務管理應用程式」——然後觀看 Claudable 即時生成程式碼，並向您展示您工作中的應用程式的即時預覽。您可以將您的應用程式部署到 Vercel，並免費與 Supabase 整合資料庫。

這個開源專案使您能夠**免費**輕鬆建構和部署專業的網頁應用程式。

如何開始？只需登入 Claude Code（或 Cursor CLI），啟動 Claudable，並描述您想建構的內容。就是這麼簡單。應用程式建構器沒有額外的訂閱費用。

## 功能
<img src="./assets/Claudable.gif" alt="Claudable Demo" style="width: 100%; max-width: 800px;">

- **強大的代理性能**：利用 Claude Code 和 Cursor CLI 代理功能的全部力量，並支援原生 MCP
- **自然語言到程式碼**：只需描述您想建構的內容，Claudable 就會生成生產就緒的 Next.js 程式碼
- **即時預覽**：當 AI 建構您的應用程式時，透過熱重載立即看到您的變更
- **零設定，即時啟動**：沒有複雜的沙箱，沒有 API 金鑰，沒有資料庫的麻煩——立即開始建構
- **漂亮的 UI**：使用 Tailwind CSS 和 shadcn/ui 生成漂亮的 UI
- **部署到 Vercel**：只需單擊一下即可將您的應用程式上線，無需配置
- **GitHub 整合**：自動版本控制和持續部署設定
- **Supabase 資料庫**：連接可隨時使用的生產 PostgreSQL 與身份驗證
- **自動錯誤檢測**：檢測應用程式中的錯誤並自動修復它們

## 技術棧
**AI 編碼代理：**
- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code/setup)**：先進的 AI 編碼代理。我們強烈建議您使用 Claude Code 以獲得最佳體驗。
  ```bash
  # 安裝
  npm install -g @anthropic-ai/claude-code
  # 登入
  claude  # 然後 > /login
  ```
- **[Cursor CLI](https://docs.cursor.com/en/cli/overview)**：用於複雜編碼任務的智慧編碼代理。它比 Claude Code 慢一點，但功能更強大。
  ```bash
  # 安裝
  curl https://cursor.com/install -fsS | bash
  # 登入
  cursor-agent login
  ```

**資料庫與部署：**
- **[Supabase](https://supabase.com/)**：將生產就緒的 PostgreSQL 資料庫直接連接到您的專案。
- **[Vercel](https://vercel.com/)**：透過一鍵部署立即發布您的作品

**沒有額外的訂閱費用，專為您打造。**

## 先決條件

在開始之前，請確保您已安裝以下軟體：
- Node.js 18+
- Python 3.10+
- Claude Code 或 Cursor CLI（已登入）
- Git

## 快速入門

在幾分鐘內讓 Claudable 在您的本機上運行：

```bash
# 克隆儲存庫
git clone https://github.com/opactorai/Claudable.git
cd Claudable

# 安裝所有依賴項（Node.js 和 Python）
npm install

# 啟動開發伺服器
npm run dev
```

您的應用程式將在以下位置可用：
- 前端：http://localhost:3000
- API 伺服器：http://localhost:8080
- API 文件：http://localhost:8080/docs

**注意**：端口會自動檢測。如果預設端口已被使用，將分配下一個可用的端口。

## 設定

### 手動設定
您也可以手動設定專案。
```bash
# 前端設定
cd apps/web
npm install

# 後端設定
cd ../api
python3 -m venv .venv
source .venv/bin/activate  # 在 Windows 上：.venv\Scripts\activate
pip install -r requirements.txt
```

`npm install` 命令會自動處理完整的設定：

1. **端口配置**：檢測可用的端口並建立 `.env` 檔案
2. **Node.js 依賴項**：安裝套件，包括工作區依賴項
3. **Python 環境**：在 `apps/api/.venv` 中建立虛擬環境
4. **Python 依賴項**：使用 `uv`（如果可用）或 `pip` 安裝套件
5. **資料庫設定**：SQLite 資料庫在首次運行時於 `data/cc.db` 自動建立

### 額外命令
```bash
npm run db:backup   # 建立您的 SQLite 資料庫的備份
                    # 使用時機：在重大變更或部署之前
                    # 建立：data/backups/cc_backup_[timestamp].db

npm run db:reset    # 將資料庫重設為初始狀態
                    # 使用時機：需要重新開始或資料損壞時
                    # 警告：這將刪除您的所有資料！

npm run clean       # 移除所有依賴項和虛擬環境
                    # 使用時機：依賴項衝突或需要全新安裝時
                    # 移除：node_modules/, apps/api/.venv/, package-lock.json
                    # 運行後：npm install 以重新安裝所有內容
```

## 使用方式

### 開始開發

1. **連接 Claude Code**：連結您的 Claude Code CLI 以啟用 AI 輔助
2. **描述您的專案**：使用自然語言描述您想建構的內容
3. **AI 生成**：觀看 AI 生成您的專案結構和程式碼
4. **即時預覽**：透過熱重載功能即時查看變更
5. **部署**：透過 Vercel 整合推送到生產環境

### API 開發

在 http://localhost:8080/docs 存取互動式 API 文件，以探索可用的端點並測試 API 功能。

### 資料庫操作

Claudable 使用 SQLite 進行本地開發，並可配置為在生產環境中使用 PostgreSQL。資料庫在首次運行時會自動初始化。

## 疑難排解

### 端口已被使用

應用程式會自動尋找可用的端口。檢查 `.env` 檔案以查看分配了哪些端口。

### 安裝失敗

```bash
# 清理所有依賴項並重試
npm run clean
npm install
```

### 權限錯誤 (macOS/Linux)

如果您遇到權限錯誤：
```bash
cd apps/api
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Claude Code 權限問題 (Windows/WSL)

如果您遇到錯誤：`Error output dangerously skip permissions cannot be used which is root sudo privileges for security reasons`

**解決方案：**
1. 不要使用 `sudo` 或以 root 使用者身份運行 Claude Code
2. 確保 WSL 中的檔案所有權正確：
   ```bash
   # 檢查目前使用者
   whoami
   
   # 將專案目錄的所有權變更為目前使用者
   sudo chown -R $(whoami):$(whoami) ~/Claudable
   ```
3. 如果使用 WSL，請確保您是從您的使用者帳戶而不是 root 運行 Claude Code
4. 驗證 Claude Code 安裝權限：
   ```bash
   # 不使用 sudo 重新安裝 Claude Code
   npm install -g @anthropic-ai/claude-code --unsafe-perm=false
   ```

## 整合指南

### GitHub
**取得權杖：** [GitHub 個人存取權杖](https://github.com/settings/tokens) → 產生新權杖（傳統）→ 選擇 `repo` 範圍

**連接：** 設定 → 服務整合 → GitHub → 輸入權杖 → 建立或連接儲存庫

### Vercel  
**取得權杖：** [Vercel 帳戶設定](https://vercel.com/account/tokens) → 建立權杖

**連接：** 設定 → 服務整合 → Vercel → 輸入權杖 → 建立新專案以進行部署

### Supabase
**取得憑證：** [Supabase 儀表板](https://supabase.com/dashboard) → 您的專案 → 設定 → API
- 專案 URL：`https://xxxxx.supabase.co`  
- Anon 金鑰：用於客戶端的公開金鑰
- Service Role 金鑰：用於伺服器端的秘密金鑰

## 設計比較

*相同的提示，不同的結果*

### Claudable
<img src="./assets/Claudable_ex.png" alt="Claudable Design" style="border-radius: 12px; width: 100%;" />

[查看 Claudable 即時演示 →](https://claudable-preview.vercel.app/)

### Lovable
<img src="./assets/Lovable_ex.png" alt="Lovable Design" style="border-radius: 12px; width: 100%;" />

[查看 Lovable 即時演示 →](https://preview--goal-track-studio.lovable.app/)

## 授權

MIT 授權。

## 即將推出的功能
這些功能正在開發中，並將很快開放。
- **新的 CLI 代理** - 相信我們，您會愛上這個的！
- **聊天檢查點** - 儲存和還原對話/程式碼庫狀態
- **進階 MCP 整合** - 與 MCP 的原生整合
- **增強的代理系統** - 子代理，AGENTS.md 整合
- **網站克隆** - 您可以從參考 URL 開始一個專案。
- 各種錯誤修復和社群 PR 合併

我們正在努力提供您一直要求的功能。敬請期待！

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=opactorai/Claudable&type=Date)](https://www.star-history.com/#opactorai/Claudable&Date)
