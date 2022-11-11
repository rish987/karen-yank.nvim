local M = {}

---@param reg_one string|number
---@param reg_two string|number
function M.sync_regs(reg_one, reg_two) vim.fn.setreg(reg_one, vim.fn.getreg(reg_two)) end

---@param num_reg_opts NumberRegOpts
local function handle_num_regs(num_reg_opts)
	if vim.api.nvim_command_output("ec v:register"):match "%w" or not num_reg_opts.enable then return end

	local x = 9
	if vim.fn.getreg(9) ~= "" then M.sync_regs(num_reg_opts.transitory_reg.reg, 9) end
	while x > 0 do
		M.sync_regs(x, x - 1)
		x = x - 1
	end
end

---@param transitory_reg TransitoryRegOpts
---@param trim_whitespace boolean
function M.handle_duplicates(transitory_reg, trim_whitespace)
	local current_yank = vim.fn.getreg(0)
	if trim_whitespace then current_yank = current_yank:gsub("%s+", "") end

	for i = 1, 9 do
		local reg = vim.fn.getreg(i)
		if trim_whitespace then reg = reg:gsub("%s+", "") end

		if reg == current_yank then
			vim.fn.setreg(i, "")
			for x = i, 9 - i do
				M.sync_regs(x, x + 1)
			end
			if vim.fn.getreg(9) ~= "" then M.sync_regs(9, transitory_reg.reg) end
			if transitory_reg.placeholder then vim.fn.setreg(transitory_reg.reg, transitory_reg.placeholder) end
		end
	end
end

---@param key string
function M.handle_delete(key)
	if vim.api.nvim_command_output("ec v:register"):match "%w" then return key end
	return '"_' .. key
end

---@param key string
---@param num_reg_opts NumberRegOpts
function M.handle_cut(key, num_reg_opts)
	handle_num_regs(num_reg_opts)
	return key
end

---@param key string
---@param yank_opts YankOpts
---@param num_reg_opts NumberRegOpts
function M.handle_yank(key, yank_opts, num_reg_opts)
	handle_num_regs(num_reg_opts)
	if key == "Y" then key = "y$" end

	local mode = vim.api.nvim_get_mode()["mode"]
	if mode == "n" then return key end

	if yank_opts.preserve_selection then
		key = key .. "gv"
		return key
	end

	if yank_opts.preserve_cursor then
		if mode == "v" then key = key .. "gvv" end
		if mode == "V" then key = key .. "gvvv" end
	end

	return key
end

---@param key string
---@param paste_opts PasteOpts
---@param num_reg_opts NumberRegOpts
function M.handle_paste(key, paste_opts, num_reg_opts)
	if paste_opts.black_hole_default then return key end

	handle_num_regs(num_reg_opts)
	if num_reg_opts.enable then key = '"0ygv' .. key end

	if paste_opts.preserve_selection then key = key .. "`[v`]" end

	return key
end

return M
