get '/upload' do 
  "
    <html>
      <head>
        <title>Image Upload</title>
        <style>
          
        </style>

      </head>
      <body>
        <h1>Upload Image</h1>
        
        <form action='/save_image' method='POST' enctype='multipart/form-data'>
          <label for='county'>County Name</label>
          <select name='county'>
            #{county_options}
          </select>
          <br/>

          <label for='zone'>Zone Name</label>
          <input name='zone'></input>
          <br/>

          <label for='training'>Training Name</label>
          <input name='training'></input>
          <br/>

          <label for='start_date'>Start Date of Training</label>
          <input type='date' name='start_date'>
          <br/>

          <label for='number_entries'>Number of entries on this form</label>
          <input type='number' name='number_entries'>
          <br/>

          <input type='file' name='file'>
          <input type='submit' value='Upload image'>
        </form>
      </body>
    </html>
  "

end

get '/show/:file_name' do |file_name|
  (county,zone,training,date) = file_name.split(/_/)

  "
    <html>
      <head>
        <style>
          .result{
            font-weight: bold;
          }
        </style>
      </head>
      <body>
        <div style='height: 50%; overflow:scroll'>
          <img src='/#{file_name}'>
        </div>
        <div height='50%'>
          <div style='font-size:200%'>
            County <span class='result'>#{county}</span>
            Zone <span class='result'>#{zone}</span>
            Training <span class='result'>#{training}</span>
            Date <span class='result'>#{date}</span>
          </div>
        </div>

      </body>
    </html>
  "

end

def county_options
  ValidationHelpers.valid_counties.map do |county|
    "<option>#{county}</option>"
  end.join("\n")
end

post '/save_image' do

  county = params["county"]
  zone = params["zone"]
  training = params["training"]
  date = params["start_date"]
  
  filename = "#{county}_#{zone}_#{training}_#{date}"
  file = params[:file][:tempfile]

  File.open("./public/#{filename}.img", 'wb') do |f|
    f.write(file.read)
  end

  pwd = `pwd`.chomp()

  full_path_file = "#{pwd}/public/#{filename}"

  `convert -resize 1024x1024\\> #{full_path_file}.img #{full_path_file}.png`
#TODO check result before deleting
  `rm  #{full_path_file}.img`
  begin
    $db.save_doc ({
      "_id" => "image-#{filename}",
      :path => "#{full_path_file}.png",
      :county => params["county"],
      :zone => params["zone"],
      :training => params["training"],
      :date => params["start_date"],
      :number_entries => params["number_entries"]
    })
  rescue

  end
  redirect to("/show/#{filename}.png")
  
end
