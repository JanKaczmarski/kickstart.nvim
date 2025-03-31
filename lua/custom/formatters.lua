local uv = vim.loop

local M = {}

-- Function to read pyproject.toml
local function read_pyproject()
	local pyproject_path = vim.fn.getcwd() .. "pyproject.toml"

	if vim.fn.filereadable(pyproject_path) == 0 then
		return nil
	end

	local lines = {}
	for line in io.lines(pyproject_path) do
		table.insert(lines, line)
	end

	local config = table.concat(lines, "\n")
	return config
end

-- Function to detect formatter
function M.get_formatters_from_pyproject()
	local config = read_pyproject()
	local formatters = {}

	-- if pyproject is missing
	if not config then
		return { "black", "isort" }
	end

	if config:match("%[tool.black%]") then
		table.insert(formatters, "black")
	elseif config:match("%[tool.ruff%]") then
		table.insert(formatters, "ruff")
	end

	if config:match("%[tool.isort%]") then
		table.insert(formatters, "isort")
	end

	local count = 0
	for _ in pairs(formatters) do
		count = count + 1
		break
	end

	if count == 0 then
		return { "black", "isort" }
	end

	return formatters
end

-- Function to detect linters
function M.get_linters_from_pyproject()
	local config = read_pyproject()
	local linters = {}

	-- if pyproject is missing
	if not config then
		return { "ruff" }
	end

	if config:match("%[tool.flake8%]") then
		table.insert(linters, "flake8")
	end
	if config:match("%[tool.ruff%]") then
		table.insert(linters, "ruff")
	end

	local count = 0
	for _ in pairs(linters) do
		count = count + 1
		break
	end

	if count == 0 then
		return { "ruff" }
	end

	return linters
end

return M
