-- CMP (completion) configuration for advanced autocompletion
-- Migrated and enhanced from user/cmp_setup.lua

local M = {}

function M.setup()
  local safe_require = _G.safe_require or require
  local cmp = safe_require('cmp')
  
  if not cmp then
    vim.notify("nvim-cmp not found, completion features will be limited", vim.log.levels.WARN)
    return
  end

  -- Setup completion sources
  local sources = {}
  
  -- Add buffer source (completes from current file)
  if pcall(require, 'cmp_buffer') then
    table.insert(sources, { 
      name = 'buffer',
      option = {
        -- Complete from all visible buffers
        get_bufnrs = function()
          return vim.api.nvim_list_bufs()
        end,
        -- Better word matching
        keyword_length = 1,        -- Start completing after 1 character
        keyword_pattern = [[\k\+]], -- Match word characters only
        max_item_count = 10,       -- Limit results for performance
      }
    })
  end
  
  -- Add path source (completes file paths)
  if pcall(require, 'cmp_path') then
    table.insert(sources, { name = 'path' })
  end

  -- Main CMP setup for insert mode
  cmp.setup({
    snippet = {
      expand = function(args)
        -- No snippet engine configured yet
        -- Could add LuaSnip here later if needed
      end,
    },
    completion = {
      completeopt = 'menu,menuone,noinsert',  -- Show menu, don't auto-insert
    },
    preselect = cmp.PreselectMode.Item,  -- Auto-select first item
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      
      -- Default Enter: Insert mode (only completes the word, doesn't replace)
      ['<CR>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          if cmp.get_active_entry() then
            -- There's an active selection, confirm it
            cmp.confirm({ 
              behavior = cmp.ConfirmBehavior.Insert,
              select = true 
            })
          else
            -- No selection, select first and confirm
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
            vim.schedule(function()
              cmp.confirm({ 
                behavior = cmp.ConfirmBehavior.Insert,
                select = true 
              })
            end)
          end
        else
          fallback()
        end
      end, { 'i' }),
      
      -- Ctrl+Enter: Replace mode (replaces larger text chunks)
      ['<C-CR>'] = cmp.mapping.confirm({ 
        behavior = cmp.ConfirmBehavior.Replace,
        select = true 
      }),
      
      -- Tab: Accept completion or navigate to next
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          -- If there's a selection, confirm it
          if cmp.get_active_entry() then
            cmp.confirm({ 
              behavior = cmp.ConfirmBehavior.Insert,
              select = true 
            })
          else
            -- No selection, select first item
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          end
        else
          fallback()
        end
      end, { 'i', 's' }),
      
      -- Shift+Tab: Navigate to previous item
      ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
        else
          fallback()
        end
      end, { 'i', 's' }),
    }),
    sources = cmp.config.sources(sources),
    formatting = {
      format = function(entry, vim_item)
        -- Show source name in completion menu
        vim_item.menu = ({
          buffer = "[Buffer]",
          path = "[Path]",
          cmdline = "[CMD]",
        })[entry.source.name]
        return vim_item
      end,
    },
    experimental = {
      ghost_text = true, -- Show preview of completion
    },
  })

  -- Setup command line completion for search (/)
  if pcall(require, 'cmp_cmdline') then
    cmp.setup.cmdline('/', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = 'buffer' }
      })
    })
    
    -- Setup command line completion for commands (:)
    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = 'path' }
      }, {
        { name = 'cmdline' }
      })
    })
  end
end

return M 