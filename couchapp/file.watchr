require 'json'

def push_and_test
#    `make combined`
  #`git log --pretty=format:'%h' -n 1 >> _attachments/app/version`
  versionDoc = {
    :version => `git log --pretty=format:'%h' -n 1`,
    :isApplicationDoc => true
  }
  `echo '#{versionDoc.to_json()}' > _docs/version.json`
  
  `git log --pretty=format:'%h' -n 1 >> _attachments/app/version`
#  `find . -name \\*.map  | xargs sed -i 's/".*app/"\\/zanzibar\\/_design\\/zanzibar\\/app/'`
  `couchapp push`
#  `pkill cucumber`
#  sleep(2)
#  puts "starting cuke"
#  cuke_result = `cucumber`
#  puts cuke_result
#  `notify-send "Cucumber fail" -i /usr/share/icons/Humanity/status/128/dialog-warning.svg &` if cuke_result.match(/fail/i)

  replace("_attachments/index.html", get_application_javascript_paths().map{|path| create_script_reference(path) }.join("\n"))
end

def get_application_javascript_paths
  javascriptFiles = ["config.js"]
  javascriptFiles.push(`find _attachments/models/  -name "*.js" | sed 's/_attachments\\///g'`.split(/\n/).sort())
  javascriptFiles.push(`find _attachments/views/  -name "*.js" | sed 's/_attachments\\///g'`.split(/\n/).sort())
  javascriptFiles.push "app.js"
  javascriptFiles.flatten!()
  return javascriptFiles
end

def create_script_reference (path)
  "<script type='text/javascript' src='#{path}'></script>"
end

def replace(file_path, contents)
  startString = "<!-- START -->"
  endString = "<!-- END -->"
  regExp = Regexp.new("#{startString}(.*)#{endString}", Regexp::MULTILINE)
  replacedResult = IO.read(file_path).gsub(regExp, "#{startString}\n#{contents}\n#{endString}")
  File.open(file_path, 'w') { |f| f.write(replacedResult) }
end


push_and_test()

#watch( '.html$') {|match_data|
#  push_and_test()
#}
watch( '.js$') {|match_data|
  push_and_test()
}
watch( '.*\.json$') {|match_data|
  push_and_test() unless match_data.to_s == "_docs\/version.json"
}
watch( '.css$') {|match_data|
  push_and_test()
}
watch( '(.*\.coffee$)' ) {|match_data|
  puts "\n"
  #result = `coffee --bare --compile #{match_data[0]} 2>&1`
  puts file_path = match_data[0]
  result = if file_path.match(/_attachments/)
    file_path.gsub!(/_attachments\//,"")
    `cd #{Dir.pwd}/_attachments; coffee --map --bare --compile #{file_path} 2>&1; cd -`
  else
    `coffee --map --bare --compile #{file_path} 2>&1`
  end
  puts result

  error = false
  result.split('\n').each{|line|
    if line.match(/error/)  then
      error = true
      puts line
      `notify-send "#{line}" -i /usr/share/icons/Humanity/status/128/dialog-warning.svg &`
    end
  }
  if not error
    push_and_test()
  end
}

