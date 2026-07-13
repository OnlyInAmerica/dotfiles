local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local skip_plugin_bootstrap = vim.env.DOTFILES_SKIP_PLUGIN_BOOTSTRAP == "1"

local function bootstrap_lazy()
  if vim.uv.fs_stat(lazypath) then
    return true
  end

  if skip_plugin_bootstrap then
    return false
  end

  if vim.fn.executable("git") ~= 1 then
    vim.notify("git is required to install lazy.nvim", vim.log.levels.ERROR)
    return false
  end

  local output = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to install lazy.nvim:\n" .. output, vim.log.levels.ERROR)
    return false
  end

  return true
end

vim.opt.swapfile = false
vim.opt.autoread = true
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.clipboard = "unnamed"
vim.opt.colorcolumn = "81"
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.ruler = true
vim.opt.scrolloff = 1

vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.autoindent = true
vim.opt.cindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 0
vim.g.netrw_altv = 1
vim.g.netrw_winsize = 15

if vim.fn.executable("ag") == 1 then
  vim.g.ackprg = "ag --vimgrep"
end

local function find_project_root(bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local startpath = bufname ~= "" and vim.fs.dirname(bufname) or vim.uv.cwd()
  local root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git" }
  local found = vim.fs.find(root_markers, { path = startpath, upward = true })

  if #found > 0 then
    return vim.fs.dirname(found[1])
  end

  return vim.uv.cwd()
end

local function set_lsp_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true }

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts)
  vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
end

if bootstrap_lazy() then
  vim.opt.runtimepath:prepend(lazypath)

  local ok, lazy = pcall(require, "lazy")
  if ok then
    lazy.setup({
      spec = {
        {
          "junegunn/fzf",
          build = function()
            vim.fn["fzf#install"]()
          end,
        },
        "mileszs/ack.vim",
        "vimwiki/vimwiki",
        {
          "fatih/vim-go",
          ft = "go",
        },
        {
          "lewis6991/gitsigns.nvim",
          opts = {
            signs = {
              add = { text = "+" },
              change = { text = "~" },
              delete = { text = "_" },
              topdelete = { text = "^" },
              changedelete = { text = "~" },
              untracked = { text = "+" },
            },
            on_attach = function(bufnr)
              local gitsigns = package.loaded.gitsigns
              local opts = { buffer = bufnr, silent = true }

              vim.keymap.set("n", "]h", gitsigns.next_hunk, opts)
              vim.keymap.set("n", "[h", gitsigns.prev_hunk, opts)
              vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, opts)
              vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, opts)
              vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, opts)
              vim.keymap.set("n", "<leader>hb", function()
                gitsigns.blame_line({ full = true })
              end, opts)
            end,
          },
        },
      },
    })
  else
    vim.notify("Failed to load lazy.nvim", vim.log.levels.ERROR)
  end
end

pcall(vim.cmd.colorscheme, "darcula")

vim.keymap.set("n", "H", "<Cmd>tabprevious<CR>")
vim.keymap.set("n", "L", "<Cmd>tabnext<CR>")
vim.keymap.set("n", "T", "<Cmd>tabnew<CR>")
vim.keymap.set("n", "<C-p>", "<Cmd>FZF<CR>")
vim.keymap.set("n", "<C-e>", "<Cmd>Lex<CR>")

function _G.ShowFuncName()
  local lnum = vim.fn.line(".")
  local col = vim.fn.col(".")
  local pattern = [[^[^ \t#/]\{2}.*[^:]\s*$]]
  local match_lnum = vim.fn.search(pattern, "bW")

  if match_lnum > 0 then
    vim.api.nvim_echo({ { vim.fn.getline(match_lnum), "ModeMsg" } }, false, {})
  end

  vim.fn.search("\\%" .. lnum .. "l\\%" .. col .. "c")
end

vim.cmd("map f <Cmd>lua ShowFuncName()<CR>")

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("dotfiles_lsp_attach", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    set_lsp_keymaps(args.buf)
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
  end,
})

vim.lsp.config("pyright", {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "pyrightconfig.json",
    ".git",
  },
})

if vim.fn.executable("pyright-langserver") == 1 then
  vim.lsp.enable("pyright")
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dotfiles_cpp_lsp", { clear = true }),
  pattern = { "c", "cpp", "objc", "objcpp" },
  callback = function(args)
    if vim.fn.executable("clangd") ~= 1 then
      return
    end

    local config = {
      name = "clangd",
      cmd = { "clangd", "--background-index" },
      root_dir = find_project_root(args.buf),
    }

    set_lsp_keymaps(args.buf)
    vim.api.nvim_buf_call(args.buf, function()
      vim.lsp.start(config)
    end)
  end,
})
