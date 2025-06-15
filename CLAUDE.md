# Nana-Kana Dialogue System

## 🎯 プロジェクト概要

女性二人（ナナ・カナ）が選択されたテーマについて掛け合いしながら深堀りする、10分程度で読み終える要約コンテンツを生成するWebアプリケーション。最終的にはGhostブログでの会員制ストーリー公開による収益化を目指す。

## 👥 キャラクター設定

### ナナ（女子高生）
- **年齢**: 18歳
- **見た目**: 元気いっぱい、明るい、学校の制服
- **性格**: 楽観的、ノリは軽い、気になることは深堀りしたくなる
- **専門分野**: TikTok、YouTube でバズったこと、若者文化

### カナ（社会人お姉さん）
- **年齢**: 26歳  
- **見た目**: クール系、黒髪+紫インナーカラー、20%地雷系、オーバーサイズオフィスカジュアル
- **性格**: シゴデキお姉さん、いろんなロールで仕事経験あり
- **専門分野**: 仕事、社会のこと
- **愛機**: MacBook Pro

## 🎭 対話スタイル

- **形式**: 友達同士の会話風
- **ボリューム**: 最大10分で概要をつかめる分量
- **差別化**: ゆっくり解説風フォーマットも検討
- **解説**: 必要都度会話の中に織り込む

## 🏗️ 技術アーキテクチャ

### フロントエンド
- **メイン**: Ghost CMS (ヘッドレス利用)
- **管理画面**: React + TypeScript (将来)
- **アニメーション**: CSS Animation or Lottie (Live2D は保留)
- **音声**: ローカル TTS + LipSync (NSFW対応のため)

### バックエンド  
- **API**: FastAPI (Python)
- **LLM**: ローカル LLM (NSFW対応、SaaS避ける)
- **推奨**: Ollama + Llama 3.2 3B
- **TTS**: ローカル実装

### インフラ
- **開発**: ローカル環境 (Mac Studio M4 Max)
- **本格運用**: AWS ECS or GCP Cloud Run
- **ストレージ**: 必要に応じて外付けSSD

### Ghost 統合
- **Content API**: 既存コンテンツ読み取り
- **Admin API**: 新規投稿作成
- **制約**: メンバーシップ機能使用時はGhostデフォルトフロントエンド必須

## 💰 収益モデル

- **目標**: 月1万円収入
- **主軸**: Ghost での会員制コンテンツ (月額課金)
- **集客**: YouTube/Note でフリー版公開 → Ghost誘導
- **将来**: NSFW コンテンツ拡張可能性

## 🚀 開発方針

### PoC 優先事項
1. **全体フロー検証**: テーマ入力 → 対話生成 → Ghost投稿 → 表示確認
2. **技術実現性**: ローカルLLM品質、生成速度、API連携
3. **MVP機能**: 静止画 + 会話形式ブログ

### PoC スコープ
```
Phase 1: ローカル環境ワークフロー
├── FastAPI サーバー
├── Ollama + Llama 3.2 3B
├── 対話生成API
└── 簡易HTML表示

Phase 2: Ghost 連携  
├── ローカルGhost環境
├── Admin API連携
└── 投稿・表示確認

Phase 3: 最低限UI
└── 10分読了レベル見た目
```

## 📂 プロジェクト構成

```
nana-kana-dialogue-system/
├── CLAUDE.md                    # このファイル
├── README.md
├── pyproject.toml              # uv依存管理
├── backend/                    # FastAPI
│   ├── app/
│   │   ├── main.py
│   │   ├── models/
│   │   ├── api/
│   │   └── services/
│   └── tests/
├── frontend/                   # Ghost テーマ & 管理画面  
│   ├── ghost-theme/
│   └── admin-ui/
├── scripts/                    # セットアップ・デプロイ
└── docs/
```

## 💻 開発環境

### メインマシン (Mac Studio M4 Max)
- **CPU**: 16コア M4 Max
- **GPU**: 40コア  
- **メモリ**: 64GB ユニファイド
- **ストレージ**: 1TB SSD
- **Python**: 3.13.5 (pyenv管理)
- **パッケージ管理**: uv

### 必須ツール
- Ollama 0.9.0 (インストール済み)
- Ghost CMS (ローカル)
- FastAPI + uvicorn

## 📋 PoC 完了条件

以下が動作すれば成功:
1. テーマ「AIの未来」入力
2. ナナ・カナの10分程度対話生成  
3. Ghost ブログ投稿
4. ブログ表示確認

## 🔗 参考リンク

- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Ghost Admin API](https://ghost.org/docs/admin-api/)
- [Ghost Content API](https://ghost.org/docs/content-api/)

## 📝 開発メモ

### 現在の状況
- [x] Ollama インストール完了
- [x] Python 3.13.5 確認
- [ ] プロジェクト初期化
- [ ] Llama 3.2 3B セットアップ
- [ ] FastAPI 基盤構築