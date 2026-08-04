(require 'package)
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)
;; 多くの作者が stable タグを打たないため、melpa-stable だけでは入らない
;; パッケージがある (dirvish など)。
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; 必要パッケージ一覧
(setq package-selected-packages
      '(use-package vertico orderless consult marginalia magit markdown-mode
                    undo-tree exec-path-from-shell
                    treemacs treemacs-nerd-icons nerd-icons))

;; GUI の Emacs.app は launchd から起動するのでログインシェルの PATH を継承せず、
;; asdf の node や pnpm 配下の typescript-language-server が見つからない。
;; window-system で絞ると --daemon 起動時 (nil) に取りこぼすので darwin 全体で行う。
(when (and (eq system-type 'darwin)
           (require 'exec-path-from-shell nil t))
  (exec-path-from-shell-initialize))

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

;; typescript-ts-mode は自身を auto-mode-alist に登録するが、それはライブラリが
;; 読み込まれた後の話で、読み込む契機が無いので .ts が fundamental-mode になる。
;; grammar が使える場合だけ明示的に対応付ける。
(with-eval-after-load 'treesit
  (when (treesit-ready-p 'typescript t)
    (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode)))
  (when (treesit-ready-p 'tsx t)
    (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))))
(require 'treesit nil t)

; Ctrl-hはBackspace扱い
(keyboard-translate ?\C-h ?\C-?)
(global-set-key (kbd "<f1>") #'help-command)
(global-set-key "\C-h" 'delete-backward-char)

;; 行数表示
(global-display-line-numbers-mode 1)

;; フォント
(set-frame-font "DejaVu Sans Mono-14")

;; macOS (Mac Port) 固有設定
(when (eq system-type 'darwin)
  ;; 左Optionをmetaに。これでM-xが効く
  (setq mac-option-modifier 'meta)
  ;; 右Optionは素の挙動を残し、特殊文字入力に使えるようにする
  (setq mac-right-option-modifier 'none)
  ;; CommandはsuperにしてmacOS標準のキーバインドと衝突させない
  (setq mac-command-modifier 'super)
  ;; リガチャ表示 (Mac Port限定)
  (when (fboundp 'mac-auto-operator-composition-mode)
    (mac-auto-operator-composition-mode 1)))

(menu-bar-mode -1)
(tool-bar-mode -1)
(setq eval-expression-print-length nil)
(show-paren-mode 1)
(setq show-paren-style 'mixed)
(global-hl-line-mode -1)
(column-number-mode t)
(global-whitespace-mode -1)
(setq whitespace-line-column 200)

;; 実ファイルへ自動保存し、中間ファイル(~ / .#)は作らない
(setq auto-save-default t
      auto-save-no-message t
      make-backup-files nil
      create-lockfiles nil)
(auto-save-visited-mode 1)
(setq auto-save-visited-interval 2)

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

;; ミニバッファ領域を単純に大きく使う
(setq resize-mini-windows t
      max-mini-window-height 0.5)

;; Vertico を有効化
(when (require 'vertico nil t)
  (setq vertico-count 30
        vertico-resize nil)
  (vertico-mode 1))

;; Vertico のファイル入力で Ido 風のディレクトリ削除を有効化
(when (require 'vertico-directory nil t)
  (defun my/vertico-backward-delete-char (n)
    "Delete char normally, but delete one path segment for file completion."
    (interactive "p")
    (if (eq 'file (vertico--metadata-get 'category))
        (vertico-directory-up n)
      (delete-backward-char n)))
  (define-key vertico-map (kbd "RET") #'vertico-directory-enter)
  ;; C-x C-f では C-h/DEL で1階層削除、それ以外は通常削除
  (define-key vertico-map (kbd "DEL") #'my/vertico-backward-delete-char)
  (define-key vertico-map (kbd "<backspace>") #'my/vertico-backward-delete-char)
  (define-key vertico-map (kbd "C-h") #'my/vertico-backward-delete-char)
  (define-key vertico-map (kbd "M-DEL") #'vertico-directory-delete-word)
  (define-key vertico-map (kbd "C-w") #'vertico-directory-delete-word)
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy))

;; 注釈表示を有効化
(when (require 'marginalia nil t)
  (marginalia-mode 1))

;; orderless で曖昧補完を有効化
(when (require 'orderless nil t)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

;; undo-tree で undo 履歴をツリー表示できるようにする
(when (require 'undo-tree nil t)
  (setq undo-tree-auto-save-history nil
        undo-tree-visualizer-timestamps t
        undo-tree-visualizer-diff t)
  (global-undo-tree-mode 1)
  (global-set-key (kbd "C-x u") #'undo-tree-visualize))

;; C-x f でプロジェクト全体を検索。git grep は追跡済みファイルしか見ないので
;; 書きかけの untracked なファイルを取りこぼす。rg があれば consult-ripgrep を使う
;; (.gitignore は尊重しつつ untracked も拾う)。
(if (locate-library "consult")
    (progn
      (autoload 'consult-ripgrep "consult" nil t)
      (autoload 'consult-git-grep "consult" nil t)
      (autoload 'consult-line "consult" nil t)
      (global-set-key (kbd "C-x f")
                      (if (executable-find "rg") #'consult-ripgrep #'consult-git-grep)))
  (global-set-key (kbd "C-x f") #'vc-git-grep))

;; C-c s でバッファ内を consult-line で検索
(when (locate-library "consult")
  (global-set-key (kbd "C-c s") #'consult-line))

;; C-x C-f は常に find-file にする
(global-set-key (kbd "C-x C-f") #'find-file)

;; C-x C-o で project-find-file
(global-set-key (kbd "C-x C-o") #'project-find-file)

;; treemacs のサイドパネル。dirvish-side は dired の平坦な一覧が土台なので、
;; アイコン付きの入れ子ツリーにするには詰める設定が多かった。treemacs は
;; 最初からその表示のためのものなので素直に済む。
;; Cmd+1 は IntelliJ のプロジェクトビューと同じキー。
(global-set-key (kbd "s-1") #'treemacs)

(with-eval-after-load 'nerd-icons
  ;; nerd-icons 既定の Symbols Nerd Font Mono は未導入。導入済みの
  ;; JetBrainsMono Nerd Font Mono に同じグリフが入っているのでそれを使う。
  (setq nerd-icons-font-family "JetBrainsMono Nerd Font Mono"))

(with-eval-after-load 'treemacs
  ;; 表示中のプロジェクトを project.el の現在地に追従させる
  (treemacs-project-follow-mode 1)
  ;; 開いているファイルをツリー上で選択状態にする
  (treemacs-follow-mode 1)
  (when (require 'treemacs-nerd-icons nil t)
    (treemacs-load-theme "nerd-icons")))

;; Go: gopls(eglot) と consult-xref で定義ジャンプ/候補表示を使う
(with-eval-after-load 'eglot
  (setf (alist-get '(go-mode go-ts-mode) eglot-server-programs nil nil #'equal)
        '("gopls")))
(add-hook 'go-mode-hook #'eglot-ensure)
(when (fboundp 'go-ts-mode)
  (add-hook 'go-ts-mode-hook #'eglot-ensure))

;; TypeScript/TSX: typescript-language-server(eglot) で定義ジャンプを使う
(with-eval-after-load 'eglot
  (setf (alist-get '(typescript-ts-mode tsx-ts-mode) eglot-server-programs nil nil #'equal)
        '("typescript-language-server" "--stdio")))
(add-hook 'typescript-ts-mode-hook #'eglot-ensure)
(add-hook 'tsx-ts-mode-hook #'eglot-ensure)

;; 定義ジャンプ: M-. に加えて Cmd+クリックでも飛べるようにする (IntelliJ と同じ操作)。
;; mac-command-modifier が super なので Cmd は s- になる。
(global-set-key (kbd "s-<mouse-1>") #'xref-find-definitions-at-mouse)

;; Flymake にはデフォルトのキー割り当てが無いので、エラー間を移動できるようにする
(with-eval-after-load 'flymake
  (define-key flymake-mode-map (kbd "C-c ! n") #'flymake-goto-next-error)
  (define-key flymake-mode-map (kbd "C-c ! p") #'flymake-goto-prev-error)
  (define-key flymake-mode-map (kbd "C-c ! l") #'flymake-show-buffer-diagnostics))

;; Biome を flymake のバックエンドにする。typescript-language-server が返すのは
;; 型エラーだけで Biome のルールは見ないため、別立てで動かす必要がある。flymake は
;; バックエンドを複数同時に扱えるので、eglot の診断と同じ波線・同じキーで並ぶ。
;; --stdin-file-path は JSON レポーターが効かないので保存済みファイルを対象にする。
(defvar-local my/flymake-biome--proc nil)

(defun my/biome-program ()
  "Return this project's biome executable, or nil when there is none."
  (when-let* ((file buffer-file-name)
              (dir (locate-dominating-file file "node_modules/.bin/biome"))
              (bin (expand-file-name "node_modules/.bin/biome" dir)))
    (and (file-executable-p bin) bin)))

(defun my/biome--position (buffer line column)
  "Convert Biome's 1-based LINE and COLUMN into a position in BUFFER."
  (with-current-buffer buffer
    (save-excursion
      (save-restriction
        (widen)
        (goto-char (point-min))
        (forward-line (1- (or line 1)))
        (forward-char (min (1- (or column 1))
                           (- (line-end-position) (point))))
        (point)))))

(defun my/biome--diagnostic (entry buffer)
  "Build a Flymake diagnostic from Biome's ENTRY, or nil if it is elsewhere."
  (let-alist entry
    ;; Biome also reports problems in biome.json itself; keep only this file's.
    (when (and .location.start
               .location.path
               (string= (file-truename .location.path)
                        (file-truename (buffer-file-name buffer))))
      (let* ((beg (my/biome--position buffer .location.start.line
                                      .location.start.column))
             ;; Biome's end column is exclusive; never produce an empty region.
             (end (max (my/biome--position buffer .location.end.line
                                           .location.end.column)
                       (1+ beg))))
        (flymake-make-diagnostic
         buffer beg end
         (cond ((equal .severity "error") :error)
               ((equal .severity "warning") :warning)
               (t :note))
         (if .category (format "%s [%s]" .message .category) .message))))))

;; This file is evaluated with dynamic binding, so the sentinel cannot close
;; over the buffer and callback; hand them over as process properties instead.
(defun my/flymake-biome--sentinel (proc _event)
  (unless (process-live-p proc)
    (let ((source (process-get proc 'biome-source))
          (report-fn (process-get proc 'biome-report)))
      (unwind-protect
          ;; Ignore a run that a newer one has already superseded.
          (when (and (buffer-live-p source)
                     (eq proc (buffer-local-value 'my/flymake-biome--proc source)))
            (funcall report-fn (my/flymake-biome--parse proc source)))
        (kill-buffer (process-buffer proc))))))

(defun my/flymake-biome (report-fn &rest _args)
  "A Flymake backend reporting Biome lint diagnostics via REPORT-FN."
  (let ((program (my/biome-program))
        (file buffer-file-name))
    (if (not (and program file))
        (funcall report-fn nil)
      (when (process-live-p my/flymake-biome--proc)
        (kill-process my/flymake-biome--proc))
      (let ((proc (make-process
                   :name "flymake-biome" :noquery t :connection-type 'pipe
                   :buffer (generate-new-buffer " *flymake-biome*")
                   :command (list program "lint" "--reporter=json" file))))
        (process-put proc 'biome-source (current-buffer))
        (process-put proc 'biome-report report-fn)
        (setq my/flymake-biome--proc proc)
        (set-process-sentinel proc #'my/flymake-biome--sentinel)))))

(defun my/flymake-biome--parse (proc buffer)
  "Read Biome's JSON from PROC and return diagnostics for BUFFER."
  (with-current-buffer (process-buffer proc)
    (goto-char (point-min))
    ;; Biome prints an "unstable option" notice before the JSON payload.
    (when (re-search-forward "^{" nil t)
      (goto-char (match-beginning 0))
      (when-let* ((json (ignore-errors (json-parse-buffer :object-type 'alist)))
                  (entries (alist-get 'diagnostics json)))
        (delq nil (mapcar (lambda (e) (my/biome--diagnostic e buffer))
                          (append entries nil)))))))

(defun my/enable-biome-flymake ()
  "Add the Biome backend to Flymake when this project uses Biome."
  (when (my/biome-program)
    (add-hook 'flymake-diagnostic-functions #'my/flymake-biome nil t)
    (flymake-mode 1)))

(add-hook 'typescript-ts-mode-hook #'my/enable-biome-flymake)
(add-hook 'tsx-ts-mode-hook #'my/enable-biome-flymake)

;; TypeScript/TSX: 外部パッケージなしで ElDoc を point 近くに出す
(defun my/eldoc-hide-child-frame ()
  "Hide the child frame used for ElDoc, if any."
  (when-let* ((buffer (and (boundp 'eldoc--doc-buffer)
                           (buffer-live-p eldoc--doc-buffer)
                           eldoc--doc-buffer))
              (window (get-buffer-window buffer t))
              (frame (window-frame window)))
    (when (frame-parameter frame 'parent-frame)
      (delete-frame frame))))

(defun my/eldoc-child-frame-position ()
  "Return the pixel position where the ElDoc child frame should appear."
  (let* ((pos (or (posn-at-point) (posn-at-point (point-max))))
         (xy (if pos (posn-x-y pos) '(0 . 0)))
         (edges (window-inside-pixel-edges))
         (line-height (frame-char-height)))
    (cons (+ (nth 0 edges) (car xy))
          (+ (nth 1 edges) (cdr xy) line-height 8))))

(defun my/eldoc-display-in-child-frame (docs interactive)
  "Display DOCS in a child frame near point for TypeScript buffers.
Fall back to the echo area when child frames are unavailable."
  (if (not (and docs
                (display-graphic-p)
                (bound-and-true-p eglot-managed-mode)
                (derived-mode-p 'typescript-ts-mode 'tsx-ts-mode)))
      (progn
        (my/eldoc-hide-child-frame)
        (eldoc-display-in-echo-area docs interactive))
    (eldoc-display-in-buffer docs nil)
    (let* ((buffer (eldoc-doc-buffer))
           (position (my/eldoc-child-frame-position))
           (window
            (display-buffer
             buffer
             `((display-buffer-in-child-frame)
               (inhibit-same-window . t)
               (window-parameters . ((mode-line-format . none)
                                     (no-other-window . t)
                                     (no-delete-other-windows . t)))
               (child-frame-parameters
                . ((undecorated . t)
                   (minibuffer . nil)
                   (no-accept-focus . t)
                   (no-focus-on-map . t)
                   (skip-taskbar . t)
                   (border-width . 0)
                   (child-frame-border-width . 1)
                   (internal-border-width . 8)
                   (left . ,(car position))
                   (top . ,(cdr position))
                   (vertical-scroll-bars . nil)
                   (horizontal-scroll-bars . nil)
                   (menu-bar-lines . 0)
                   (tool-bar-lines . 0)))))))
      (when window
        (set-window-dedicated-p window t)
        (set-window-fringes window 8 8)
        (with-current-buffer buffer
          (setq-local mode-line-format nil)
          (setq-local cursor-type nil)
          (setq-local truncate-lines nil))
        (fit-window-to-buffer window 12 3 100 24)
        (let ((frame (window-frame window)))
          (set-frame-position frame (car position) (cdr position))
          (make-frame-visible frame))))))

(defun my/eldoc-doc-buffer ()
  "Display the ElDoc buffer, producing it first when needed."
  (interactive)
  (if (and (boundp 'eldoc--doc-buffer)
           (buffer-live-p eldoc--doc-buffer))
      (eldoc-doc-buffer t)
    (eldoc)
    (when (and (boundp 'eldoc--doc-buffer)
               (buffer-live-p eldoc--doc-buffer))
      (eldoc-doc-buffer t))))

(defun my/typescript-eldoc-setup ()
  "Use a child frame for ElDoc in TypeScript buffers."
  (setq-local eldoc-display-functions '(my/eldoc-display-in-child-frame))
  (add-hook 'pre-command-hook #'my/eldoc-hide-child-frame nil t)
  (local-set-key (kbd "C-c e") #'my/eldoc-doc-buffer))

(add-hook 'typescript-ts-mode-hook #'my/typescript-eldoc-setup)
(add-hook 'tsx-ts-mode-hook #'my/typescript-eldoc-setup)

;; xref の候補表示を minibuffer (consult) に統一
(when (locate-library "consult")
  (autoload 'consult-xref "consult-xref" nil t)
  (with-eval-after-load 'xref
    (setq xref-show-xrefs-function #'consult-xref
          xref-show-definitions-function #'consult-xref)))

;; eldoc はミニバッファに1行で表示
(setq eldoc-echo-area-use-multiline-p nil)

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

;; C-x g で今いるリポジトリの magit-status
(global-set-key (kbd "C-x g") #'magit-status)
;; 変更行の中で実際に変わった箇所だけを全ハンクで強調 (delta の emph 相当)
(setq magit-diff-refine-hunk 'all)

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
   '(color-theme-sanityinc-tomorrow consult go-mode marginalia markdown-mode orderless
				    terraform-mode undo-tree vertico)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
