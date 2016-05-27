# This comes from Strawberry's FileUploadView
post '/save_image' do

  question_set = params["question_set"]
  county = params["county"]
  zone = params["zone"]
  training = params["training"]
  date = params["start_date"]
  page = params["page_number"]
  
  filename = "#{question_set}_#{county}_#{zone}_#{training}_#{date}_#{page}"
  file = params[:file][:tempfile]

  File.open("./public/#{filename}.img", 'wb') do |f|
    f.write(file.read)
  end

  pwd = `pwd`.chomp()

  full_path_file = "#{pwd}/public/#{filename}"

  `convert -resize 1024x1024\\> "#{full_path_file}.img" "#{full_path_file}.png"`
#TODO check result before deleting
  `rm  "#{full_path_file}.img"`
  begin
    $db.save_doc ({
      "_id" => "image-#{filename}",
      :path => "#{full_path_file}.png",
      :question_set => params["question_set"],
      :county => params["county"],
      :zone => params["zone"],
      :training => params["training"],
      :date => params["start_date"],
      :number_pages_total => params["number_pages_total"],
      :page_number => params["page_number"],
      :number_entries_page => params["number_entries_page"],
      :number_entries_total => params["number_entries_total"]
    })
  rescue

  end
  redirect to("http://gooseberry.tangerinecentral.org:5984/gooseberry/_design/strawberry/index.html")
  
end
