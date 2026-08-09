#!/usr/bin/env bash
# 新しい端末にこの Emacs 環境を用意する。
# リポジトリを ~/.emacs.d に clone してから実行すること。何度実行してもよい。
set -euo pipefail

info() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
skip() { printf '    %s\n' "$1"; }

# ---------------------------------------------------------------- 前提確認

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew が必要です: https://brew.sh" >&2
  exit 1
fi

# tree-sitter の文法はソースから C をコンパイルするため
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools が必要です: xcode-select --install" >&2
  exit 1
fi

# ---------------------------------------------------------------- Emacs 本体

info "Emacs (Mac Port)"
if [ -d /Applications/Emacs.app ]; then
  skip "/Applications/Emacs.app は導入済み"
else
  # Mac Port は Homebrew 本体には無い。サードパーティ tap は明示的な信頼が要る。
  brew tap railwaycat/emacsmacport
  brew trust railwaycat/emacsmacport
  brew install --cask railwaycat/emacsmacport/emacs-mac
fi

# ---------------------------------------------------------------- 外部コマンド

info "コマンドライン依存"
# rg: C-x f のプロジェクト全文検索 (git grep と違い untracked も拾う)
# tree: M-! tree でのディレクトリ俯瞰
for pkg in ripgrep tree; do
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    skip "$pkg は導入済み"
  else
    brew install "$pkg"
  fi
done

# ---------------------------------------------------------------- フォント

info "フォント"
# init.el が JetBrainsMono Nerd Font Mono を選ぶ。treemacs のアイコンも同じ書体で賄う。
if system_profiler SPFontsDataType 2>/dev/null | grep -q "JetBrainsMono Nerd Font"; then
  skip "JetBrainsMono Nerd Font は導入済み"
else
  brew install --cask font-jetbrains-mono-nerd-font
fi

# ---------------------------------------------------------------- Node

info "Node"
# TypeScript の言語サーバは node 製。プロジェクト側の .tool-versions が要求する
# バージョンは、そのリポジトリを clone してから asdf install で入れること。
if command -v asdf >/dev/null 2>&1; then
  asdf plugin list 2>/dev/null | grep -qx nodejs || asdf plugin add nodejs
  skip "asdf あり。各リポジトリでは asdf install を実行すること"
else
  skip "asdf が無い。node を別の方法で用意すること"
fi

# ---------------------------------------------------------------- 言語サーバ

info "TypeScript 言語サーバ"
# TypeScript 7 のプロジェクトはリポジトリ同梱のネイティブバイナリを使うので不要だが、
# 6 以前のプロジェクト向けにフォールバックとして入れておく。
if command -v pnpm >/dev/null 2>&1; then
  if command -v typescript-language-server >/dev/null 2>&1; then
    skip "typescript-language-server は導入済み"
  else
    pnpm add -g typescript-language-server typescript
    cat <<'EOS'
    pnpm 11 はグローバルの実行ファイルを $PNPM_HOME/bin に置く。
    PATH に入っていなければシェルの設定に次を足すこと:

      case ":$PATH:" in
        *":$PNPM_HOME/bin:"*) ;;
        *) export PATH="$PNPM_HOME/bin:$PATH" ;;
      esac
EOS
  fi
else
  skip "pnpm が無い。スキップ"
fi

# ---------------------------------------------------------------- Emacs 側

EMACS=/Applications/Emacs.app/Contents/MacOS/Emacs
[ -x "$EMACS" ] || EMACS=emacs

info "Emacs パッケージ"
# init.el を読むだけで、不足しているパッケージは自動で入る。
"$EMACS" --batch -l ~/.emacs.d/init.el \
  --eval '(message "packages: %d installed" (length package-selected-packages))'

info "tree-sitter 文法"
# 文法はプラットフォーム依存のバイナリなのでリポジトリに含めていない。
# これが無いと .ts が fundamental-mode で開き、eglot も動かない。
"$EMACS" --batch -l ~/.emacs.d/init.el --eval '(my/install-treesit-grammars)'

# ---------------------------------------------------------------- 確認

info "確認"
"$EMACS" --batch -l ~/.emacs.d/init.el --eval '
(progn
  (require (quote treesit))
  (dolist (lang (mapcar #'"'"'car treesit-language-source-alist))
    (message "  grammar %-12s => %s" lang (treesit-ready-p lang t)))
  (dolist (cmd (list "rg" "tree" "node"))
    (message "  %-12s => %s" cmd (or (executable-find cmd) "見つからない")))
  (message "  theme        => %s" custom-enabled-themes))'

cat <<'EOS'

残りは手作業:
  - Emacs.app を Finder から初回起動する (Gatekeeper の確認が出る)
  - 各リポジトリで asdf install を実行し .tool-versions のバージョンを揃える
EOS
