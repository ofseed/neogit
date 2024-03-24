local Buffer = require("neogit.lib.buffer")
local ui = require("neogit.buffers.log_view.ui")
local config = require("neogit.config")
local popups = require("neogit.popups")
local notification = require("neogit.lib.notification")
local status_maps = require("neogit.config").get_reversed_status_maps()
local CommitViewBuffer = require("neogit.buffers.commit_view")

---@class LogViewBuffer
---@field commits CommitLogEntry[]
---@field internal_args table
---@field files string[]
local M = {}
M.__index = M

---Opens a popup for selecting a commit
---@param commits CommitLogEntry[]|nil
---@param internal_args table|nil
---@param files string[]|nil list of files to filter by
---@return LogViewBuffer
function M.new(commits, internal_args, files)
  local instance = {
    files = files,
    commits = commits,
    internal_args = internal_args,
    buffer = nil,
  }

  setmetatable(instance, M)

  return instance
end

function M:close()
  self.buffer:close()
  self.buffer = nil
end

function M:open()
  self.buffer = Buffer.create {
    name = "NeogitLogView",
    filetype = "NeogitLogView",
    kind = config.values.log_view.kind,
    context_highlight = false,
    status_column = " ",
    mappings = {
      v = {
        [popups.mapping_for("CherryPickPopup")] = popups.open("cherry_pick", function(p)
          p { commits = self.buffer.ui:get_commits_in_selection() }
        end),
        [popups.mapping_for("BranchPopup")] = popups.open("branch", function(p)
          p { commits = self.buffer.ui:get_commits_in_selection() }
        end),
        [popups.mapping_for("CommitPopup")] = popups.open("commit", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("FetchPopup")] = popups.open("fetch"),
        [popups.mapping_for("MergePopup")] = popups.open("merge", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("PushPopup")] = popups.open("push", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("RebasePopup")] = popups.open("rebase", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("RemotePopup")] = popups.open("remote"),
        [popups.mapping_for("RevertPopup")] = popups.open("revert", function(p)
          p { commits = self.buffer.ui:get_commits_in_selection() }
        end),
        [popups.mapping_for("ResetPopup")] = popups.open("reset", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("TagPopup")] = popups.open("tag", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("PullPopup")] = popups.open("pull"),
        [popups.mapping_for("DiffPopup")] = popups.open("diff", function(p)
          local items = self.buffer.ui:get_commits_in_selection()
          p {
            section = { name = "log" },
            item = { name = items },
          }
        end),
      },
      n = {
        [popups.mapping_for("CherryPickPopup")] = popups.open("cherry_pick", function(p)
          p { commits = { self.buffer.ui:get_commit_under_cursor() } }
        end),
        [popups.mapping_for("BranchPopup")] = popups.open("branch", function(p)
          p { commits = { self.buffer.ui:get_commit_under_cursor() } }
        end),
        [popups.mapping_for("CommitPopup")] = popups.open("commit", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("FetchPopup")] = popups.open("fetch"),
        [popups.mapping_for("MergePopup")] = popups.open("merge", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("PushPopup")] = popups.open("push", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("RebasePopup")] = popups.open("rebase", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("RemotePopup")] = popups.open("remote"),
        [popups.mapping_for("RevertPopup")] = popups.open("revert", function(p)
          p { commits = { self.buffer.ui:get_commit_under_cursor() } }
        end),
        [popups.mapping_for("ResetPopup")] = popups.open("reset", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("TagPopup")] = popups.open("tag", function(p)
          p { commit = self.buffer.ui:get_commit_under_cursor() }
        end),
        [popups.mapping_for("DiffPopup")] = popups.open("diff", function(p)
          local item = self.buffer.ui:get_commit_under_cursor()
          p {
            section = { name = "log" },
            item = { name = item },
          }
        end),
        [popups.mapping_for("PullPopup")] = popups.open("pull"),
        [popups.mapping_for("HelpPopup")] = popups.open("help", function(p)
          -- Since any other popup can be launched from help, build an ENV for any of them.
          local commit = self.buffer.ui:get_commit_under_cursor()
          local commits = { commit }

          p {
            buffer = "log",
            branch = { commits = commits },
            cherry_pick = { commits = commits },
            commit = { commit = commit },
            merge = { commit = commit },
            push = { commit = commit },
            rebase = { commit = commit },
            revert = { commits = commits },
            reset = { commit = commit },
            tag = { commit = commit },
            stash = {},
            diff = {
              section = { name = "log" },
              item = { name = commit },
            },
            ignore = {
              paths = {},
              git_root = require("neogit.lib.git").repo.git_root,
            },
            remote = {},
            fetch = {},
            pull = {},
            log = {},
            worktree = {},
          }
        end),
        [status_maps["YankSelected"]] = function()
          local yank = self.buffer.ui:get_commit_under_cursor()
          if yank then
            yank = string.format("'%s'", yank)
            vim.cmd.let("@+=" .. yank)
            vim.cmd.echo(yank)
          else
            vim.cmd("echo ''")
          end
        end,
        ["q"] = function()
          self:close()
        end,
        ["<esc>"] = function()
          self:close()
        end,
        ["<enter>"] = function()
          local commit = self.buffer.ui:get_commit_under_cursor()
          if commit then
            CommitViewBuffer.new(commit, self.files):open()
          end
        end,
        ["<c-k>"] = function()
          pcall(vim.cmd, "normal! zc")

          vim.cmd("normal! k")
          for _ = vim.fn.line("."), 0, -1 do
            if vim.fn.foldlevel(".") > 0 then
              break
            end

            vim.cmd("normal! k")
          end

          pcall(vim.cmd, "normal! zo")
          vim.cmd("normal! zz")
        end,
        ["<c-j>"] = function()
          pcall(vim.cmd, "normal! zc")

          vim.cmd("normal! j")
          for _ = vim.fn.line("."), vim.fn.line("$"), 1 do
            if vim.fn.foldlevel(".") > 0 then
              break
            end

            vim.cmd("normal! j")
          end

          pcall(vim.cmd, "normal! zo")
          vim.cmd("normal! zz")
        end,
        ["<tab>"] = function()
          pcall(vim.cmd, "normal! za")
        end,
      },
    },
    render = function()
      return ui.View(self.commits, self.internal_args)
    end,
  }
end

return M
