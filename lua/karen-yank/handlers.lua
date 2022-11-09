local M = {}

local function sync_regs(reg_one, reg_two) vim.cmd(string.format("let @%s=@%s", reg_one, reg_two)) end

---@param num_reg_opts NumberRegOpts
local function handle_num_regs(num_reg_opts)
	if vim.api.nvim_command_output("ec v:register"):match "%w" or not num_reg_opts.enable then return end

	local x = 9
	while x > 0 do
		sync_regs(x, x - 1)
		x = x - 1
	end
end

---@param transitory_reg string
function M.handle_duplicates(transitory_reg)
	local current_yank = vim.fn.getreg(0)
	for i = 1, 9 do
		local reg = vim.fn.getreg(i)
		if reg == current_yank then
			vim.fn.setreg(i, "")
			if i ~= 9 then sync_regs(transitory_reg, 9) end
			for x = i, 8 do
				sync_regs(x, x + 1)
			end
			if i ~= 9 then
				sync_regs(9, transitory_reg)
				vim.fn.setreg(transitory_reg, "")
			end
		end
	end
end

function M.handle_delete(key_lhs)
	local key_rhs = key_lhs

	if vim.api.nvim_command_output("ec v:register"):match "%w" then return key_rhs end

	key_rhs = '"_' .. key_rhs
	return key_rhs
end

---@param yank_opts YankOpts
function M.handle_yank(key_lhs, yank_opts)
	local key_rhs = key_lhs

	handle_num_regs(yank_opts.number_regs)

	local mode = vim.api.nvim_get_mode()["mode"]
	if mode == "n" then return key_rhs end

	if yank_opts.preserve_seleciton then
		key_rhs = key_rhs .. "gv"
		return key_rhs
	end

	if yank_opts.preserve_cursor then
		if mode == "v" then key_rhs = key_rhs .. "gvv" end
		if mode == "V" then key_rhs = key_rhs .. "gvvv" end
	end

	return key_rhs
end

---@param paste_opts PasteOpts
---@param num_reg_opts NumberRegOpts
function M.handle_paste(key_lhs, paste_opts, num_reg_opts)
	local key_rhs = key_lhs

	if not paste_opts.black_hole_default then handle_num_regs(num_reg_opts) end
	if num_reg_opts.enable then key_rhs = '"0ygv' .. key_rhs end
	if paste_opts.preserve_selection then key_rhs = key_rhs .. "`[v`]" end

	return key_rhs
end

return M
