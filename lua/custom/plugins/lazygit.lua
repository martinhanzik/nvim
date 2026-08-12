vim.pack.add { 'https://github.com/kdheepak/lazygit.nvim' }

vim.keymap.set('n', '<leader>gg', '<Cmd>LazyGit<CR>', { desc = 'Open LazyGit', silent = true })
