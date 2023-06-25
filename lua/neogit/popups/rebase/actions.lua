local git = require("neogit.lib.git")
local input = require("neogit.lib.input")

local CommitSelectViewBuffer = require("neogit.buffers.commit_select_view")
local FuzzyFinderBuffer = require("neogit.buffers.fuzzy_finder")

local M = {}

function M.base_branch()
  local value = git.config.get("neogit.baseBranch")
  return value:is_set() and value.value or "master"
end

function M.onto_base(popup)
  git.rebase.rebase_onto(M.base_branch(), popup:get_arguments())
end

function M.onto_pushRemote(popup)
  local pushRemote = git.branch.pushRemote()
  if not pushRemote then
    pushRemote = git.branch.set_pushRemote()
  end

  if pushRemote then
    git.rebase.rebase_onto(
      string.format("refs/remotes/%s/%s", pushRemote, git.branch.current()),
      popup:get_arguments()
    )
  end
end

function M.onto_upstream(popup)
  local upstream
  if git.repo.upstream.ref then
    upstream = string.format("refs/remotes/%s", git.repo.upstream.ref)
  else
    local target = FuzzyFinderBuffer.new(git.branch.get_remote_branches()):open_async()
    if not target then
      return
    end

    upstream = string.format("refs/remotes/%s", target)
  end

  git.rebase.rebase_onto(upstream, popup:get_arguments())
end

function M.onto_elsewhere(popup)
  local target = FuzzyFinderBuffer.new(git.branch.get_all_branches()):open_async()
  if target then
    git.rebase.rebase_onto(target, popup:get_arguments())
  end
end

function M.interactively(popup)
  local commit = popup.state.env.commit[1] or CommitSelectViewBuffer.new(git.log.list()):open_async()
  if commit then
    git.rebase.rebase_interactive(commit, popup:get_arguments())
  end
end

function M.continue()
  git.rebase.continue()
end

function M.skip()
  git.rebase.skip()
end

-- TODO: Extract to rebase lib?
function M.abort()
  if input.get_confirmation("Abort rebase?", { values = { "&Yes", "&No" }, default = 2 }) then
    git.cli.rebase.abort.call_sync():trim()
  end
end

return M
