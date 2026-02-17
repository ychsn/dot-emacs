(require 'package)
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)

;; 必要パッケージ一覧
(setq package-selected-packages
      '(use-package vertico orderless consult marginalia magit))

;; 必要パッケージをインストール
(defun my/install-selected-packages ()
  (interactive)
  (unless package-archive-contents
    (package-refresh-contents))
  (dolist (pkg package-selected-packages)
    (unless (package-installed-p pkg)
      (package-install pkg))))

;; 使用テーマ
(require 'color-theme-sanityinc-tomorrow)
(color-theme-sanityinc-tomorrow--define-theme day)

;; Tree-sitter の文法定義リスト
(setq treesit-language-source-alist
      '((typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")))

; Ctrl-hはBackspace扱い
(keyboard-translate ?\C-h ?\C-?)
(global-set-key (kbd "<f1>") #'help-command)
(global-set-key "\C-h" 'delete-backward-char)

;; 行数表示
(global-display-line-numbers-mode 1)

;; フォント
(set-frame-font "DejaVu Sans Mono-14")


(menu-bar-mode -1)
(tool-bar-mode -1)
(setq eval-expression-print-length nil)
(show-paren-mode 1)
(setq show-paren-style 'mixed)
(global-hl-line-mode -1)
(column-number-mode t)
(global-whitespace-mode -1)
(setq whitespace-line-column 200)

(setq whitespace-style '(face              ; faceを使って視覚化する。
                         trailing          ; 行末の空白を対象とする。
                         ;lines-tail        ; 長すぎる行のうち
                         spaces
                         space-mark
                         newline
                         newline-mark
                         empty             ; 先頭/末尾の空行
                         tab-mark))

(setq whitespace-display-mappings
      '((space-mark ?\u3000 [?\u25a1])
        (space-mark   ?\xA0  [?\xA4]  [?_]) ; hard space - currency
        (space-mark   ?\x8A0 [?\x8A4] [?_]) ; hard space - currency
        (space-mark   ?\x920 [?\x924] [?_]) ; hard space - currency
        (space-mark   ?\xE20 [?\xE24] [?_]) ; hard space - currency
        (space-mark   ?\xF20 [?\xF24] [?_]) ; hard space - currency
        ;(newline-mark ?\n    [?\u21B5 ?\n] [?\u240D ?\n])
        ))

;; 保存前に自動でクリーンアップ
(setq whitespace-action '(auto-cleanup))

;; ミニバッファ履歴を保存
(savehist-mode 1)

;; Vertico を有効化
(when (require 'vertico nil t)
  (setq vertico-count 20)
  (vertico-mode 1))

;; 注釈表示を有効化
(when (require 'marginalia nil t)
  (marginalia-mode 1))

;; orderless で曖昧補完を有効化
(when (require 'orderless nil t)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

;; C-x f で git grep (consult がなければ vc-git-grep)
(if (locate-library "consult")
    (progn
      (autoload 'consult-git-grep "consult" nil t)
      (global-set-key (kbd "C-x f") #'consult-git-grep))
  (global-set-key (kbd "C-x f") #'vc-git-grep))

;; ghq 管理リポジトリを素早く選択する
(defun my/ghq-select-repo ()
  (unless (executable-find "ghq")
    (user-error "ghq command not found"))
  (completing-read "GHQ repo: " (process-lines "ghq" "list" "-p") nil t))

(defun my/ghq-dired ()
  (interactive)
  (dired (my/ghq-select-repo)))

(defun my/ghq-magit-status ()
  (interactive)
  (unless (fboundp 'magit-status)
    (user-error "magit is not available"))
  (magit-status (my/ghq-select-repo)))

(global-set-key (kbd "C-c g d") #'my/ghq-dired)
(global-set-key (kbd "C-c g s") #'my/ghq-magit-status)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes '(sanityinc-tomorrow-day))
 '(custom-safe-themes
   '("6bdc4e5f585bb4a500ea38f563ecf126570b9ab3be0598bdf607034bb07a8875"
     default))
 '(package-selected-packages
   '(color-theme-sanityinc-tomorrow consult marginalia orderless
				    terraform-mode vertico)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
