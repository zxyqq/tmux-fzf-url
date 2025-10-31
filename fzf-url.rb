#!/usr/bin/env ruby
# frozen_string_literal: true

require 'shellwords'

def halt(message)
  system "tmux display-message #{Shellwords.escape(message)}"
  exit
end

def extract_urls(line)
  line.scan(%r{(?:https?|file)://[-a-zA-Z0-9@:%_+.~#?&/=]+[-a-zA-Z0-9@%_+.~#?&/=!]+}x)
end

# 获取终端内容
lines = `tmux capture-pane -J -p -S -99999`
urls = lines.each_line.map(&:strip).reject(&:empty?)
            .flat_map { |l| extract_urls(l) }.reverse.uniq
halt 'No URLs found' if urls.empty?

# fzf 选择
header = 'CTRL-Y: Copy to Windows clipboard | ENTER: Open in Windows'
max_size = `tmux display-message -p "\#{client_width} \#{client_height}"`.split.map(&:to_i)
size = [[*urls, header].map(&:length).max + 2, urls.length + 5].zip(max_size).map(&:min).join(',')

selected = IO.popen("fzf --tmux #{size} --multi --expect ctrl-y --header #{Shellwords.escape(header)}", 'r+') do |io|
  urls.each { |url| io.puts url }
  io.close_write
  io.readlines.map(&:chomp)
end

exit if selected.length < 2

if selected.first == 'ctrl-y'
  # 复制到 Windows 剪贴板
  text = selected.drop(1).join("\n")
  system("echo #{Shellwords.escape(text)} | clip.exe")
  halt '✓ Copied to Windows clipboard'
else
  # 在 Windows 中打开 URL
  selected.drop(1).each do |url|
    system("cmd.exe /c start #{Shellwords.escape(url)}")
  end
  halt "✓ Opened #{selected.drop(1).length} URL(s) in Windows"
end
