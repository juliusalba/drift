#!/usr/bin/env ruby
# Adds any Swift files under DriftBar/ that aren't yet in the DriftBar target.
# Also adds Help/ as a folder reference (blue folder) with resources build phase.
# Safe to run repeatedly — idempotent.

require "xcodeproj"
require "pathname"

ROOT = Pathname(__dir__).expand_path
PROJECT = ROOT.join("DriftBar.xcodeproj")
SOURCE_DIR = ROOT.join("DriftBar")
abort("missing project at #{PROJECT}") unless PROJECT.exist?

project = Xcodeproj::Project.open(PROJECT.to_s)
target  = project.targets.find { |t| t.name == "DriftBar" }
abort("DriftBar target not found") unless target

main_group = project.main_group["DriftBar"] || project.main_group.groups.find { |g| g.display_name == "DriftBar" }
abort("DriftBar group not found") unless main_group

# Existing file refs by resolved path (absolute)
existing_paths = project.files.map { |f|
  begin
    p = f.real_path
    p.realpath.to_s
  rescue
    nil
  end
}.compact.to_set

added = []
skipped = 0

# 1. All Swift files directly under DriftBar/ (non-recursive — matches the flat layout)
Dir.glob(SOURCE_DIR.join("*.swift")).sort.each do |swift_path|
  abs = Pathname(swift_path).realpath.to_s
  if existing_paths.include?(abs)
    skipped += 1
    next
  end
  ref = main_group.new_reference(swift_path)
  ref.name = File.basename(swift_path)
  target.add_file_references([ref])
  added << File.basename(swift_path)
end

# 2. Help/ folder as folder reference + resources build phase
help_dir = SOURCE_DIR.join("Help")
if help_dir.directory?
  abs_help = help_dir.realpath.to_s
  unless existing_paths.include?(abs_help)
    folder_ref = main_group.new_reference(help_dir.to_s)
    folder_ref.name = "Help"
    folder_ref.last_known_file_type = "folder"
    target.resources_build_phase.add_file_reference(folder_ref, true)
    added << "Help/"
  end
end

project.save

puts "----------------------------------------"
puts "Drift Xcode sync complete"
puts "  Added:   #{added.length} item(s)"
added.each { |a| puts "    + #{a}" }
puts "  Skipped (already present): #{skipped}"
puts "----------------------------------------"
