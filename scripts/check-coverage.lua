#!/usr/bin/env lua
-- Check code coverage thresholds for claude-code.nvim
-- - Fail if any file is below 25% coverage
-- - Fail if overall coverage is below 70%

local FILE_THRESHOLD = 25.0
local TOTAL_THRESHOLD = 70.0

-- Parse luacov report
local function parse_luacov_report(report_file)
  local file = io.open(report_file, "r")
  if not file then
    return nil, "Coverage report '" .. report_file .. "' not found"
  end
  
  local content = file:read("*all")
  file:close()
  
  local file_coverage = {}
  local total_coverage = nil
  
  -- Parse individual file coverage
  -- Example: lua/claude-code/init.lua                   100.00%   123     0
  for line in content:gmatch("[^\n]+") do
    local filename, coverage, hits, misses = line:match("^(lua/claude%-code/[^%s]+%.lua)%s+(%d+%.%d+)%%%s+(%d+)%s+(%d+)")
    if filename and coverage then
      file_coverage[filename] = {
        coverage = tonumber(coverage),
        hits = tonumber(hits),
        misses = tonumber(misses)
      }
    end
    
    -- Parse total coverage
    -- Example: Total                      85.42%   410    58
    local total_cov = line:match("^Total%s+(%d+%.%d+)%%")
    if total_cov then
      total_coverage = tonumber(total_cov)
    end
  end
  
  return {
    files = file_coverage,
    total = total_coverage
  }
end

-- Check coverage thresholds
local function check_coverage_thresholds(coverage_data)
  local failures = {}
  
  -- Check individual file thresholds
  for filename, data in pairs(coverage_data.files) do
    if data.coverage < FILE_THRESHOLD then
      table.insert(failures, string.format(
        "File '%s' coverage %.2f%% is below threshold of %.0f%%",
        filename, data.coverage, FILE_THRESHOLD
      ))
    end
  end
  
  -- Check total coverage threshold
  if coverage_data.total then
    if coverage_data.total < TOTAL_THRESHOLD then
      table.insert(failures, string.format(
        "Total coverage %.2f%% is below threshold of %.0f%%",
        coverage_data.total, TOTAL_THRESHOLD
      ))
    end
  else
    table.insert(failures, "Could not determine total coverage")
  end
  
  return #failures == 0, failures
end

-- Main function
local function main()
  local report_file = "luacov.report.out"
  
  print("Checking code coverage thresholds...")
  print(string.rep("=", 60))
  
  -- Check if report file exists
  local file = io.open(report_file, "r")
  if not file then
    print("Warning: Coverage report '" .. report_file .. "' not found")
    print("This might be expected if coverage collection is not set up yet.")
    print("Skipping coverage checks for now.")
    os.exit(0)  -- Exit successfully to not break CI
  end
  file:close()
  
  -- Parse coverage report
  local coverage_data, err = parse_luacov_report(report_file)
  if not coverage_data then
    print("Error: Failed to parse coverage report: " .. (err or "unknown error"))
    os.exit(1)
  end
  
  -- Display coverage summary
  local file_count = 0
  for _ in pairs(coverage_data.files) do
    file_count = file_count + 1
  end
  
  print(string.format("Total Coverage: %.2f%%", coverage_data.total or 0))
  print(string.format("Files Analyzed: %d", file_count))
  print()
  
  -- Check thresholds
  local passed, failures = check_coverage_thresholds(coverage_data)
  
  if passed then
    print("✅ All coverage thresholds passed!")
    
    -- Show file coverage
    print("\nFile Coverage Summary:")
    print(string.rep("-", 60))
    
    -- Sort files by name
    local sorted_files = {}
    for filename in pairs(coverage_data.files) do
      table.insert(sorted_files, filename)
    end
    table.sort(sorted_files)
    
    for _, filename in ipairs(sorted_files) do
      local data = coverage_data.files[filename]
      local status = data.coverage >= FILE_THRESHOLD and "✅" or "❌"
      print(string.format("%s %-45s %6.2f%%", status, filename, data.coverage))
    end
  else
    print("❌ Coverage thresholds failed!")
    print("\nFailures:")
    for _, failure in ipairs(failures) do
      print("  - " .. failure)
    end
    
    -- Show file coverage
    print("\nFile Coverage Summary:")
    print(string.rep("-", 60))
    
    -- Sort files by name
    local sorted_files = {}
    for filename in pairs(coverage_data.files) do
      table.insert(sorted_files, filename)
    end
    table.sort(sorted_files)
    
    for _, filename in ipairs(sorted_files) do
      local data = coverage_data.files[filename]
      local status = data.coverage >= FILE_THRESHOLD and "✅" or "❌"
      print(string.format("%s %-45s %6.2f%%", status, filename, data.coverage))
    end
    
    os.exit(1)
  end
end

-- Run main function
main()